# WorldTask Handler Development Guide

## Overview

This guide explains how to create new WorldTask handlers for capturing different types of world-bound data. The system uses a registry pattern to route tasks to specific handlers based on the `FieldName` property.

## Handler Architecture

### Interface Contract

All handlers must implement `IWorldTaskHandler`:

```java
public interface IWorldTaskHandler {
    /**
     * Get the task type/field name this handler supports.
     * @return The field name (e.g., "Location", "WgRegionId")
     */
    String getFieldName();

    /**
     * Start handling a task for a player.
     * This typically involves entering a "selection mode" where the player
     * can interact with the world to provide the required data.
     * 
     * @param player The player handling the task
     * @param taskId The task ID
     * @param inputJson Optional input data from the workflow session
     */
    void startTask(Player player, int taskId, String inputJson);

    /**
     * Check if a player is currently handling a task of this type.
     * @param player The player to check
     * @return true if the player is handling a task of this type
     */
    boolean isHandling(Player player);

    /**
     * Cancel the current task for a player.
     * @param player The player whose task should be cancelled
     */
    void cancel(Player player);

    /**
     * Get the current task ID for a player, if any.
     * @param player The player
     * @return The task ID, or null if not handling a task
     */
    Integer getTaskId(Player player);
}
```

### Handler Lifecycle

```
startTask() called
  ↓
Player enters "task mode"
  ↓
Plugin listens for handler-specific commands in chat
  ↓
Player executes command (e.g., "save")
  ↓
Handler validates captured data
  ↓
Handler calls worldTasksApi.complete(taskId, outputJson)
  ↓
Task completed, player exits task mode
```

## Example: LocationTaskHandler

The `LocationTaskHandler` is a complete, simple example of implementing a task handler:

```java
public class LocationTaskHandler implements IWorldTaskHandler {
    private static final Logger LOGGER = Logger.getLogger(LocationTaskHandler.class.getName());
    private static final String FIELD_NAME = "Location";

    private final WorldTasksApi worldTasksApi;
    private final Plugin plugin;
    
    // Track active tasks: player → TaskContext
    private final Map<Player, TaskContext> activeTasksByPlayer = new HashMap<>();

    /**
     * Internal context for tracking task state
     */
    private static class TaskContext {
        final int taskId;
        final String inputJson;
        boolean paused;

        TaskContext(int taskId, String inputJson) {
            this.taskId = taskId;
            this.inputJson = inputJson;
            this.paused = false;
        }
    }

    public LocationTaskHandler(WorldTasksApi worldTasksApi, Plugin plugin) {
        this.worldTasksApi = worldTasksApi;
        this.plugin = plugin;
    }

    @Override
    public String getFieldName() {
        return FIELD_NAME;
    }

    @Override
    public void startTask(Player player, int taskId, String inputJson) {
        TaskContext context = new TaskContext(taskId, inputJson);
        activeTasksByPlayer.put(player, context);

        player.sendMessage("§6[WorldTask] Capture your current location.");
        player.sendMessage("§7[WorldTask] Task ID: " + taskId);
        player.sendMessage("§eType 'save' to capture your current position (x, y, z, yaw, pitch)");
        player.sendMessage("§eType 'pause' to temporarily pause the task");
        player.sendMessage("§eType 'resume' to continue after pausing");
        player.sendMessage("§7Or type 'cancel' to abort.");

        LOGGER.info("Started Location task for player " + player.getName() + " (task " + taskId + ")");
    }

    @Override
    public boolean isHandling(Player player) {
        return activeTasksByPlayer.containsKey(player);
    }

    @Override
    public void cancel(Player player) {
        TaskContext context = activeTasksByPlayer.remove(player);
        if (context != null) {
            player.sendMessage("§c[WorldTask] Task cancelled.");
            LOGGER.info("Cancelled Location task for player " + player.getName() + " (task " + context.taskId + ")");
        }
    }

    @Override
    public Integer getTaskId(Player player) {
        TaskContext context = activeTasksByPlayer.get(player);
        return context != null ? context.taskId : null;
    }

    /**
     * Handle chat input from player during task.
     * Processes 'save', 'cancel', 'pause', 'resume' commands.
     * 
     * @param player The player
     * @param message The chat message
     * @return true if the message was handled and should be cancelled
     */
    public boolean onPlayerChat(Player player, String message) {
        TaskContext context = activeTasksByPlayer.get(player);
        if (context == null) return false;

        String cmd = message.trim().toLowerCase();
        
        if (cmd.equals("save")) {
            handleSave(player, context);
            return true;
        } else if (cmd.equals("cancel")) {
            cancel(player);
            return true;
        } else if (cmd.equals("pause") || cmd.equals("suspend")) {
            handlePause(player, context);
            return true;
        } else if (cmd.equals("resume")) {
            handleResume(player, context);
            return true;
        }
        
        return false;
    }

    private void handleSave(Player player, TaskContext context) {
        if (context.paused) {
            player.sendMessage("§c[WorldTask] Task is paused. Type 'resume' to continue.");
            return;
        }

        try {
            Location location = player.getLocation();
            
            double x = location.getX();
            double y = location.getY();
            double z = location.getZ();
            float yaw = location.getYaw();
            float pitch = location.getPitch();
            String worldName = location.getWorld() != null ? location.getWorld().getName() : "unknown";
            
            player.sendMessage("§a[WorldTask] Location captured!");
            player.sendMessage(String.format("§7Position: (%.2f, %.2f, %.2f)", x, y, z));
            player.sendMessage(String.format("§7Rotation: yaw=%.2f, pitch=%.2f", yaw, pitch));
            player.sendMessage("§7Completing task...");
            
            completeTask(player, context, x, y, z, yaw, pitch, worldName);
            
        } catch (Exception e) {
            player.sendMessage("§c[WorldTask] Error capturing location: " + e.getMessage());
            LOGGER.warning("Error in handleSave for task " + context.taskId + ": " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void handlePause(Player player, TaskContext context) {
        context.paused = true;
        player.sendMessage("§e[WorldTask] Task paused.");
        player.sendMessage("§7Type 'resume' to continue, or 'cancel' to abort.");
        LOGGER.info("Paused Location task " + context.taskId + " for player " + player.getName());
    }

    private void handleResume(Player player, TaskContext context) {
        if (!context.paused) {
            player.sendMessage("§c[WorldTask] Task is not paused.");
            return;
        }
        
        context.paused = false;
        player.sendMessage("§a[WorldTask] Task resumed.");
        player.sendMessage("§7Type 'save' to capture your current position.");
        LOGGER.info("Resumed Location task " + context.taskId + " for player " + player.getName());
    }

    private void completeTask(Player player, TaskContext context, double x, double y, double z, 
                              float yaw, float pitch, String worldName) {
        JsonObject output = new JsonObject();
        output.addProperty("fieldName", FIELD_NAME);
        output.addProperty("x", x);
        output.addProperty("y", y);
        output.addProperty("z", z);
        output.addProperty("yaw", yaw);
        output.addProperty("pitch", pitch);
        output.addProperty("worldName", worldName);
        output.addProperty("capturedAt", System.currentTimeMillis());
        
        String outputJson = output.toString();

        worldTasksApi.complete(context.taskId, outputJson)
            .thenAccept(completedTask -> {
                plugin.getServer().getScheduler().runTask(plugin, () -> {
                    activeTasksByPlayer.remove(player);
                    player.sendMessage("§a[WorldTask] ✓ Task completed! Location saved.");
                    LOGGER.info("Completed Location task for player " + player.getName() 
                        + " (task " + context.taskId + ") at position: (" + x + ", " + y + ", " + z + ")");
                });
            })
            .exceptionally(ex -> {
                plugin.getServer().getScheduler().runTask(plugin, () -> {
                    player.sendMessage("§c[WorldTask] Failed to complete task: " + ex.getMessage());
                    LOGGER.warning("Failed to complete Location task " + context.taskId + ": " + ex.getMessage());
                });
                return null;
            });
    }
}
```

## Creating Your Own Handler

### Step 1: Define the Handler Class

```java
public class CustomDataTaskHandler implements IWorldTaskHandler {
    private static final Logger LOGGER = Logger.getLogger(CustomDataTaskHandler.class.getName());
    private static final String FIELD_NAME = "CustomFieldName";  // Change this

    private final WorldTasksApi worldTasksApi;
    private final Plugin plugin;
    private final Map<Player, TaskContext> activeTasksByPlayer = new HashMap<>();

    // Internal context class
    private static class TaskContext {
        final int taskId;
        final String inputJson;
        boolean paused;
        // Add handler-specific state here
        
        TaskContext(int taskId, String inputJson) {
            this.taskId = taskId;
            this.inputJson = inputJson;
            this.paused = false;
        }
    }

    public CustomDataTaskHandler(WorldTasksApi worldTasksApi, Plugin plugin) {
        this.worldTasksApi = worldTasksApi;
        this.plugin = plugin;
    }

    @Override
    public String getFieldName() {
        return FIELD_NAME;
    }

    // Implement other interface methods...
}
```

### Step 2: Implement startTask()

```java
@Override
public void startTask(Player player, int taskId, String inputJson) {
    TaskContext context = new TaskContext(taskId, inputJson);
    activeTasksByPlayer.put(player, context);

    // Parse inputJson to extract any constraints/configuration
    if (inputJson != null && !inputJson.isEmpty()) {
        try {
            JsonObject input = JsonParser.parseString(inputJson).getAsJsonObject();
            // Extract configuration: 
            // context.someConfig = input.get("someConfig").getAsString();
        } catch (Exception e) {
            LOGGER.warning("Failed to parse input JSON: " + e.getMessage());
        }
    }

    // Send instructions to player
    player.sendMessage("§6[WorldTask] Instructions for your task...");
    player.sendMessage("§eType 'save' to complete...");
    player.sendMessage("§7Or type 'cancel' to abort.");

    LOGGER.info("Started " + FIELD_NAME + " task for player " + player.getName() + " (task " + taskId + ")");
}
```

### Step 3: Implement Chat Command Handling

```java
public boolean onPlayerChat(Player player, String message) {
    TaskContext context = activeTasksByPlayer.get(player);
    if (context == null) return false;

    String cmd = message.trim().toLowerCase();
    
    if (cmd.equals("save")) {
        handleSave(player, context);
        return true;
    } else if (cmd.equals("cancel")) {
        cancel(player);
        return true;
    } else if (cmd.equals("pause")) {
        handlePause(player, context);
        return true;
    } else if (cmd.equals("resume")) {
        handleResume(player, context);
        return true;
    }
    // Add handler-specific commands here
    // else if (cmd.startsWith("custom ")) { ... }
    
    return false;
}
```

### Step 4: Implement Data Capture & Validation

```java
private void handleSave(Player player, TaskContext context) {
    if (context.paused) {
        player.sendMessage("§c[WorldTask] Task is paused. Type 'resume' to continue.");
        return;
    }

    try {
        // Capture data
        String capturedData = captureData(player, context);
        
        // Validate
        if (!isValidData(capturedData, context)) {
            player.sendMessage("§c[WorldTask] Invalid data captured. Try again.");
            return;
        }
        
        // Complete
        completeTask(player, context, capturedData);
        
    } catch (Exception e) {
        player.sendMessage("§c[WorldTask] Error: " + e.getMessage());
        LOGGER.warning("Error in handleSave: " + e.getMessage());
    }
}

private String captureData(Player player, TaskContext context) {
    // Extract data specific to your handler
    // Example: Player location, selection, block data, etc.
    return "captured_data";
}

private boolean isValidData(String data, TaskContext context) {
    // Validate against inputJson constraints
    // Check if data meets requirements
    return true;
}
```

### Step 5: Build OutputJson and Complete Task

```java
private void completeTask(Player player, TaskContext context, String capturedData) {
    // Build output JSON following the expected schema
    JsonObject output = new JsonObject();
    output.addProperty("fieldName", FIELD_NAME);
    output.addProperty("data", capturedData);
    output.addProperty("capturedAt", System.currentTimeMillis());
    // Add additional properties as needed
    
    String outputJson = output.toString();

    // Call API to complete task (async)
    worldTasksApi.complete(context.taskId, outputJson)
        .thenAccept(completedTask -> {
            plugin.getServer().getScheduler().runTask(plugin, () -> {
                activeTasksByPlayer.remove(player);
                player.sendMessage("§a[WorldTask] ✓ Task completed!");
                LOGGER.info("Completed " + FIELD_NAME + " task for player " + player.getName());
            });
        })
        .exceptionally(ex -> {
            plugin.getServer().getScheduler().runTask(plugin, () -> {
                player.sendMessage("§c[WorldTask] Failed to complete task: " + ex.getMessage());
                LOGGER.warning("Failed to complete task " + context.taskId + ": " + ex.getMessage());
            });
            return null;
        });
}
```

### Step 6: Register the Handler

In your plugin's main initialization:

```java
public class KnKPlugin extends JavaPlugin {
    @Override
    public void onEnable() {
        // ... existing code ...
        
        // Create and register handlers
        WorldTaskHandlerRegistry registry = new WorldTaskHandlerRegistry();
        registry.registerHandler(new WgRegionIdTaskHandler(worldTasksApi, this));
        registry.registerHandler(new LocationTaskHandler(worldTasksApi, this));
        registry.registerHandler(new CustomDataTaskHandler(worldTasksApi, this));  // NEW
        
        // Store in plugin for access elsewhere
        getServer().getPluginManager().registerEvents(
            new RegionTaskEventListener(registry),
            this
        );
    }
}
```

## Best Practices

### 1. State Management

Use TaskContext to track per-player state:
```java
private static class TaskContext {
    final int taskId;
    final String inputJson;
    boolean paused;
    // Add handler-specific state
    String partialData;  // e.g., intermediate results
    int retryCount;
}
```

### 2. Error Handling

Always wrap logic in try-catch:
```java
try {
    // operations
} catch (Exception e) {
    player.sendMessage("§c[WorldTask] Error: " + e.getMessage());
    LOGGER.warning("Task error: " + e.getMessage());
    e.printStackTrace();
}
```

### 3. Async Operations

Use CompletableFuture for API calls:
```java
worldTasksApi.complete(taskId, outputJson)
    .thenAccept(result -> {
        // Schedule on main thread
        plugin.getServer().getScheduler().runTask(plugin, () -> {
            // Main thread operations
        });
    })
    .exceptionally(ex -> {
        // Handle errors
        return null;
    });
```

### 4. Cleanup

Always clean up resources on cancel/failure:
```java
@Override
public void cancel(Player player) {
    TaskContext context = activeTasksByPlayer.remove(player);
    if (context != null) {
        // Cleanup: remove temp structures, restore state, etc.
        cleanupTemporaryResources(player, context);
        
        player.sendMessage("§c[WorldTask] Task cancelled.");
        LOGGER.info("Cancelled task for " + player.getName());
    }
}
```

### 5. Logging

Log important events:
```java
LOGGER.info("Started Location task for player " + player.getName() + " (task " + taskId + ")");
LOGGER.warning("Error in handleSave: " + e.getMessage());
LOGGER.fine("Player paused task");
```

## Testing Your Handler

1. **Unit Tests**: Mock WorldTasksApi and test state transitions
2. **Integration Tests**: Run plugin with test server
3. **Manual Testing**:
   ```
   1. Create a workflow in web app
   2. Note the LinkCode
   3. /worldtask claim {code}
   4. Execute handler commands (save, cancel, etc.)
   5. Verify task completed in web app
   ```

## Common Patterns

### Input Constraints Pattern

```java
if (inputJson != null) {
    try {
        JsonObject input = JsonParser.parseString(inputJson).getAsJsonObject();
        if (input.has("parentRegionId")) {
            context.parentRegionId = input.get("parentRegionId").getAsString();
        }
    } catch (Exception e) {
        LOGGER.warning("Failed to parse constraints: " + e.getMessage());
    }
}
```

### Pause/Resume Pattern

```java
private void handlePause(Player player, TaskContext context) {
    context.paused = true;
    player.sendMessage("§e[WorldTask] Task paused. Type 'resume' to continue.");
}

private void handleResume(Player player, TaskContext context) {
    if (!context.paused) {
        player.sendMessage("§c[WorldTask] Task is not paused.");
        return;
    }
    context.paused = false;
    player.sendMessage("§a[WorldTask] Task resumed.");
}
```

### Validation Pattern

```java
if (!isValidData(data, context)) {
    player.sendMessage("§c[WorldTask] Validation failed: " + getValidationError(data, context));
    return;
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| API calls hang | Check WorldTasksApi connection, check async executor |
| Chat commands not intercepted | Verify PlayerChatEvent listener is registered |
| Context not found | Ensure startTask() was called before onPlayerChat() |
| Task never completes | Check OutputJson format, verify complete() call happens |
| Memory leaks | Ensure activeTasksByPlayer entries are removed on cancel/complete |

