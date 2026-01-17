# Knights & Kings Inventory Menu System - Architecture & Design Guide

**Version:** 1.0  
**Date:** January 17, 2026  
**Audience:** Developers implementing the v2 menu system

---

## 1. System Architecture

### 1.1 Layered Architecture

```
┌─────────────────────────────────────────────────────┐
│            Presentation Layer                        │
│     (Bukkit Inventory Rendering)                     │
│  - ItemStack rendering                              │
│  - Lore formatting                                  │
│  - Click event handling                             │
└────────────────┬────────────────────────────────────┘
                 │
┌─────────────────────────────────────────────────────┐
│             Display Engine Layer                     │
│     (MenuDisplayed & Rendering Logic)                │
│  - Slot calculation                                 │
│  - Overflow handling                                │
│  - Priority-based layering                          │
│  - Variable resolution                              │
└────────────────┬────────────────────────────────────┘
                 │
┌─────────────────────────────────────────────────────┐
│            Model Layer                              │
│   (Menu, MenuSection, MenuItem)                     │
│  - Hierarchical composition                         │
│  - Property definitions                             │
│  - Action registration                              │
│  - Click handlers                                   │
└────────────────┬────────────────────────────────────┘
                 │
┌─────────────────────────────────────────────────────┐
│            Integration Layer                        │
│  - KNK Core APIs                                   │
│  - Player/User context                             │
│  - Event broadcasting                              │
│  - Data persistence (optional)                     │
└─────────────────────────────────────────────────────┘
```

### 1.2 Component Structure

```
Menu (Container)
  │
  ├─ MenuSession (Runtime context)
  │   ├─ Player
  │   ├─ Open inventory reference
  │   └─ Menu state variables
  │
  ├─ MenuUtil (Helper service)
  │   ├─ Slot calculations
  │   ├─ Overlap detection
  │   └─ Coordinate conversions
  │
  ├─ VariableResolver (Variable system)
  │   ├─ VariableString parsing
  │   ├─ Context-aware resolution
  │   └─ Result caching
  │
  └─ MenuRenderer (Display engine)
      ├─ Layout calculation
      ├─ Item positioning
      ├─ Overflow handling
      └─ Inventory rendering
```

---

## 2. Design Patterns

### 2.1 Composite Pattern

The Menu/MenuSection/MenuItem hierarchy implements the **Composite Pattern**:

```java
// Simplified example
interface IMenuObject {
  List<T> getChildren();
  void render(Inventory inv);
}

class Menu implements IMenuObject {
  List<MenuSection> children = new ArrayList<>();
  
  @Override
  public void render(Inventory inv) {
    children.forEach(section -> section.render(inv));
  }
}

class MenuSection implements IMenuObject {
  List<MenuItem> children = new ArrayList<>();
  
  @Override
  public void render(Inventory inv) {
    children.forEach(item -> item.render(inv));
  }
}

class MenuItem implements IMenuObject {
  ItemStack itemStack;
  
  @Override
  public void render(Inventory inv) {
    inv.setItem(slot, itemStack);
  }
}
```

**Benefits:**
- Treat individual items and collections uniformly
- Recursive rendering works naturally
- Easy to add new container types

### 2.2 Builder Pattern

Menu construction should use fluent builder pattern:

```java
Menu menu = new Menu("Main Menu")
  .setHeight(5)
  .addChildren(
    new MenuSection("Headers")
      .setWidth(9).setHeight(1)
      .addChildren(new MenuItem("Title")),
    new MenuSection("Content")
      .setWidth(9).setHeight(3)
      .setListMode(ListMode.GRID)
      .addChildren(item1, item2, item3),
    new MenuSection("Footer")
      .setWidth(9).setHeight(1)
      .addChildren(backButton, closeButton)
  );
```

### 2.3 Strategy Pattern (Display Modes)

Different rendering strategies for different display modes:

```java
interface DisplayStrategy {
  void render(MenuObject obj, Inventory inv, MenuSession session);
}

class NormalDisplay implements DisplayStrategy { ... }
class DisabledDisplay implements DisplayStrategy { ... }
class HighlightDisplay implements DisplayStrategy { ... }
class HideDisplay implements DisplayStrategy { ... }
```

### 2.4 Observer Pattern (Event System)

Broadcast menu state changes:

```java
interface MenuStateListener {
  void onMenuOpened(MenuOpenedEvent event);
  void onMenuClosed(MenuClosedEvent event);
  void onItemClicked(ItemClickedEvent event);
  void onMenuUpdated(MenuUpdatedEvent event);
}

class MenuSession {
  private List<MenuStateListener> listeners = new ArrayList<>();
  
  public void addListener(MenuStateListener listener) {
    listeners.add(listener);
  }
  
  private void notifyMenuOpened() {
    listeners.forEach(l -> l.onMenuOpened(event));
  }
}
```

### 2.5 Template Method (Variable Resolution)

VariableString uses template method for resolution:

```java
abstract class BaseVariable {
  public final String resolve(MenuSession context) {
    String raw = getRawPattern();
    List<Placeholder> placeholders = extractPlaceholders(raw);
    String resolved = resolvePlaceholders(placeholders, context);
    cacheResult(resolved);  // Template steps
    return resolved;
  }
  
  protected abstract String getRawPattern();
  protected abstract String resolvePlaceholder(Placeholder p, MenuSession ctx);
}
```

---

## 3. Key Implementation Details

### 3.1 Slot Calculation Strategy

**Problem**: Given a position (x,y), width, height, and alignment, which inventory slots should be occupied?

**Solution**: Use set-based calculations with alignment bias

```java
public static Set<Integer> calculateSlots(
    int startX, int startY, 
    int width, int height,
    AlignVertical alignVert,
    AlignHorizontal alignHori) {
  
  Set<Integer> slots = new HashSet<>();
  
  for (int row = 0; row < height; row++) {
    int y = alignVert.equals(TOP) ? startY + row : startY - row;
    int rowStartSlot = getRowStart(y) + startX;
    int rowEndSlot = getRowEnd(y) - (8 - startX);
    
    for (int col = 0; col < width; col++) {
      int slot = alignHori.equals(LEFT) 
        ? rowStartSlot + col 
        : rowEndSlot - col;
      slots.add(slot);
    }
  }
  
  return slots;
}
```

**Key Insight**: Always calculate from original position, then apply alignment bias for each row.

### 3.2 Variable Resolution with Context

**Problem**: VariableString needs access to dynamic runtime data (player, time, etc.)

**Solution**: Resolution context with method reflection

```java
class VariableResolver {
  private final MenuSession session;
  private final Map<String, Object> contextVars;
  
  public String resolve(String pattern) {
    Pattern placeholderPattern = Pattern.compile("\\$([\w.]+)\\$");
    Matcher m = placeholderPattern.matcher(pattern);
    
    StringBuffer sb = new StringBuffer();
    while (m.find()) {
      String path = m.group(1);  // e.g., "player.getName"
      Object value = resolveProperty(path);
      m.appendReplacement(sb, String.valueOf(value));
    }
    m.appendTail(sb);
    
    return sb.toString();
  }
  
  private Object resolveProperty(String path) {
    String[] parts = path.split("\\.");
    Object current = contextVars.get(parts[0]);
    
    for (int i = 1; i < parts.length; i++) {
      current = invokeGetter(current, parts[i]);
    }
    
    return current;
  }
  
  private Object invokeGetter(Object obj, String property) {
    String methodName = "get" + capitalize(property);
    try {
      Method method = obj.getClass().getMethod(methodName);
      return method.invoke(obj);
    } catch (NoSuchMethodException e) {
      return null;
    }
  }
}
```

**Performance Optimization**: Cache results in VariableString

```java
class VariableString {
  private final String pattern;
  private String cachedResult;
  private long lastResolutionTime;
  
  public String resolve(MenuSession session) {
    String result = resolver.resolve(pattern, session);
    this.cachedResult = result;
    this.lastResolutionTime = System.currentTimeMillis();
    return result;
  }
  
  public String getCachedResult() {
    return cachedResult;
  }
  
  // For efficient lore updates: use cached result to find index
  public int findInLore(List<String> lore) {
    return lore.indexOf(cachedResult);
  }
}
```

### 3.3 Efficient Lore Updates

**Problem**: Updating a MenuItem's lore requires full ItemStack recreation, which is expensive.

**Solution**: Minimal ItemMeta updates using cached VariableString results

```java
class MenuItem {
  private List<VariableString> description;
  private ItemStack itemStack;
  
  public void updateLore(MenuSession session) {
    ItemMeta meta = itemStack.getItemMeta();
    List<String> currentLore = meta.getLore();
    
    // Update only description lines (first items in lore)
    for (int i = 0; i < description.size(); i++) {
      String newText = description.get(i).resolve(session);
      if (i < currentLore.size()) {
        currentLore.set(i, newText);
      }
    }
    
    meta.setLore(currentLore);
    itemStack.setItemMeta(meta);
    // Single ItemStack update instead of recreation
  }
}
```

**Key Insight**: VariableString objects should always be the first lines in lore, so their indexes correspond to array positions for O(1) lookup.

### 3.4 Priority-Based Layering

**Problem**: Sections can overlap; which should be visible?

**Solution**: Render in priority order, highest priority last (top layer)

```java
class MenuRenderer {
  public void render(Menu menu, Inventory inventory, MenuSession session) {
    List<MenuSection> sections = menu.getChildren();
    
    // Sort by priority (ascending)
    sections.sort((a, b) -> 
      a.getPriority().getLevel() - b.getPriority().getLevel()
    );
    
    for (MenuSection section : sections) {
      renderSection(section, inventory, session);
    }
    
    // Items rendered last are visible on top
  }
}
```

### 3.5 Click Handling Pipeline

**Problem**: Click events need to traverse hierarchy to find clicked item, validate permissions, execute actions.

**Solution**: Chain of Responsibility pattern

```java
class ClickEventHandler {
  public void handle(InventoryClickEvent bukkitEvent, MenuSession session) {
    int slot = bukkitEvent.getSlot();
    
    // Find which menu item occupies this slot
    MenuItem item = session.getMenuItemAtSlot(slot);
    if (item == null) return;
    
    // Check if item can be clicked
    if (!item.canClick(bukkitEvent.getClick(), bukkitEvent.getWhoClicked())) {
      bukkitEvent.setCancelled(true);
      return;
    }
    
    // Execute all registered actions
    item.getActions().forEach(action -> 
      action.execute(session, bukkitEvent)
    );
    
    // Broadcast event
    session.notifyItemClicked(new ItemClickedEvent(item, bukkitEvent));
    
    // Re-render menu
    session.updateDisplay();
  }
}
```

---

## 4. Performance Optimization Strategies

### 4.1 Rendering Optimization

1. **Lazy ItemStack Creation**
   ```java
   // Don't create ItemStack until needed
   class MenuItem {
     private ItemStack itemStack; // null until first render
     
     public ItemStack getItemStack() {
       if (itemStack == null) {
         itemStack = buildItemStack();
       }
       return itemStack;
     }
   }
   ```

2. **Batch Updates**
   ```java
   // Update multiple items at once instead of individual inventory updates
   class MenuSession {
     private Set<MenuItem> dirtyItems = new HashSet<>();
     
     public void updateItem(MenuItem item) {
       dirtyItems.add(item);
     }
     
     public void commitUpdates() {
       Inventory inv = getInventory();
       dirtyItems.forEach(item -> {
         inv.setItem(item.getSlot(), item.getItemStack());
       });
       dirtyItems.clear();
     }
   }
   ```

3. **Memoization for Slot Calculations**
   ```java
   class MenuSection {
     private Set<Integer> calculatedSlots;
     
     public Set<Integer> getSlots() {
       if (calculatedSlots == null) {
         calculatedSlots = MenuUtil.calculateSlots(...);
       }
       return calculatedSlots;
     }
   }
   ```

### 4.2 Variable Resolution Optimization

1. **Result Caching**
   ```java
   class VariableString {
     private String cachedResult;
     private MenuSession lastSession;
     
     public String resolve(MenuSession session) {
       if (session.equals(lastSession) && cachedResult != null) {
         return cachedResult; // Return cached if context unchanged
       }
       // ... resolve and cache
     }
   }
   ```

2. **Lazy Resolution**
   ```java
   // Only resolve variables when accessing lore, not during storage
   public String getDisplayName(MenuSession session) {
     return name.resolve(session); // Resolve on-demand
   }
   ```

### 4.3 Memory Optimization

1. **Weak References for Cached Menus**
   ```java
   private Map<String, WeakReference<Menu>> menuCache = new WeakHashMap<>();
   ```

2. **Object Pooling for Common Items**
   ```java
   class BackgroundItem {
     private static final Queue<ItemStack> pool = new LinkedList<>();
     
     public static ItemStack acquire() {
       return pool.isEmpty() ? createNew() : pool.poll();
     }
     
     public static void release(ItemStack item) {
       pool.offer(item);
     }
   }
   ```

---

## 5. Error Handling & Validation

### 5.1 Validation Checklist

Before rendering a menu, validate:

- [ ] All sections fit within menu bounds
- [ ] No slot collisions between sections
- [ ] All sections have valid dimensions (width > 0, height > 0)
- [ ] Alignments are valid
- [ ] Variable strings have valid syntax
- [ ] Click handlers are registered for clickable items
- [ ] Background item is defined
- [ ] Menu name resolves successfully

### 5.2 Error Recovery

```java
class MenuValidator {
  public List<ValidationError> validate(Menu menu) {
    List<ValidationError> errors = new ArrayList<>();
    
    // Check dimensions
    if (menu.getHeight() < 1 || menu.getHeight() > 6) {
      errors.add(new ValidationError("Invalid menu height: " + menu.getHeight()));
    }
    
    // Check sections
    for (MenuSection section : menu.getChildren()) {
      errors.addAll(validateSection(section));
    }
    
    // Check collisions
    Set<Integer> occupiedSlots = new HashSet<>();
    for (MenuSection section : menu.getChildren()) {
      Set<Integer> sectionSlots = section.getSlots();
      for (int slot : sectionSlots) {
        if (occupiedSlots.contains(slot)) {
          errors.add(new ValidationError("Slot collision at slot " + slot));
        }
      }
      occupiedSlots.addAll(sectionSlots);
    }
    
    return errors;
  }
}
```

---

## 6. Thread Safety Considerations

### 6.1 Immutable Definitions

Menu definitions should be immutable after creation:

```java
public final class Menu {
  private final String name;
  private final List<MenuSection> children; // unmodifiable
  
  public Menu(String name, List<MenuSection> children) {
    this.name = name;
    this.children = Collections.unmodifiableList(new ArrayList<>(children));
  }
}
```

### 6.2 Synchronized Session State

MenuSession contains mutable runtime state:

```java
public class MenuSession {
  private final Object stateLock = new Object();
  private Map<String, Object> variables = new HashMap<>();
  
  public void setVariable(String key, Object value) {
    synchronized (stateLock) {
      variables.put(key, value);
    }
  }
  
  public Object getVariable(String key) {
    synchronized (stateLock) {
      return variables.get(key);
    }
  }
}
```

### 6.3 Async Rendering

Render off-game thread, update inventory on main thread:

```java
public void renderAsync(Menu menu, Player player) {
  Bukkit.getScheduler().runTaskAsynchronously(plugin, () -> {
    Inventory inv = Bukkit.createInventory(null, 27, menu.getName());
    // Expensive calculations here
    
    Bukkit.getScheduler().runTask(plugin, () -> {
      player.openInventory(inv); // Back on main thread
    });
  });
}
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

- **Slot Calculation Tests**: Verify correct slots for all combinations of alignment, position, size
- **Variable Resolution Tests**: Test placeholder extraction and value lookup
- **Collision Detection Tests**: Verify overlap detection works correctly
- **Priority Ordering Tests**: Ensure correct render order

### 7.2 Integration Tests

- **Menu Rendering Tests**: Full menu from definition to inventory
- **Click Handling Tests**: Event handling and action execution
- **Variable Update Tests**: Lore updates with different context

### 7.3 Performance Tests

- **Large Menu Rendering**: 1000+ items should render in <500ms
- **Rapid Clicks**: 100 clicks/sec should not cause lag
- **Memory Usage**: Monitor for leaks during repeated open/close

---

## 8. Migration Path from Legacy

### Phase 1: Parallel Implementation
- Implement v2 menu system alongside legacy
- Create adapters to convert legacy Menu definitions to v2
- Run both systems until v2 is complete

### Phase 2: Gradual Migration
- Convert one menu at a time to v2
- Use adapter layer to smooth transition
- Test thoroughly before switching

### Phase 3: Cleanup
- Remove legacy menu system
- Remove adapter layer
- Update all references to use v2

---

## 9. Future Enhancements

### Short Term (1-2 months)
- [ ] Keyboard navigation support
- [ ] Animation framework
- [ ] CSS-like styling system

### Medium Term (3-6 months)
- [ ] Web API menu definitions
- [ ] Menu persistence/caching layer
- [ ] Advanced overlay system (menus within menus)

### Long Term (6+ months)
- [ ] Plugin system for custom renderers
- [ ] Accessibility features (screen reader support)
- [ ] Mobile app synchronization

---

## 10. Decision Log

| Decision | Rationale | Alternative Considered |
|----------|-----------|------------------------|
| Use Composite Pattern | Flexible hierarchy, recursive rendering | Single flat structure |
| Cache VariableString results | Avoid repeated resolution in tight loops | Always re-resolve |
| Priority-based layering | Intuitive control of element visibility | Z-index system |
| Immutable menu definitions | Thread-safe, functional programming style | Mutable with locks |
| Async rendering | Prevent main thread blocking | Synchronous only |

