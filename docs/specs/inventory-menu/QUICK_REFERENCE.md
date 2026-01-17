# Inventory Menu System - Quick Reference

**Quick navigation for developers implementing the inventory menu feature**

---

## File Structure

```
docs/specs/inventory-menu/
├── REQUIREMENTS_INVENTORY_MENU.md     # Complete functional & non-functional requirements
├── ARCHITECTURE_DESIGN.md              # Design patterns, implementation strategies, optimization
├── QUICK_REFERENCE.md                  # This file
└── (future) IMPLEMENTATION_GUIDE.md    # Step-by-step development guide
```

---

## Core Concepts at a Glance

### 1. Hierarchical Composition
```
Menu (9 wide × N tall)
└── MenuSection (flexible positioning, sizing, alignment)
    └── MenuItem (individual clickable item)
```

### 2. Slot System
- **Total slots**: 9 × row_count (e.g., 27 for 3 rows, 54 for 6 rows)
- **Coordinates**: (X: 0-8, Y: 0-N)
- **Slot ID**: Row × 9 + Column
- **Functions**: MenuUtil handles all conversions

### 3. Variable Resolution
```
VariableString: "Player: $player.getName$"
                ↓ resolves to ↓
Result: "Player: John"
Cache: Stores "Player: John" for efficient lookup
```

### 4. Key Patterns Used
| Pattern | Use Case | Benefit |
|---------|----------|---------|
| **Composite** | Menu/Section/Item hierarchy | Recursive rendering |
| **Builder** | Menu construction | Fluent, readable configuration |
| **Strategy** | Display modes (normal, disabled, etc.) | Pluggable rendering strategies |
| **Observer** | Menu state changes | Loose coupling to listeners |
| **Chain of Responsibility** | Click event handling | Multi-step validation/execution |

---

## Class Hierarchy (v2 Recommendation)

```java
// Base interfaces
IMenuObject<T>
IMenuObjectParent<Parent, Child>
IMenuObjectChild<Child, Parent>
IScalable<T>
IClickable

// Core classes
MenuObject<T extends IMenuObject>
├── Menu extends MenuObject implements IMenuObjectParent
├── MenuSection<C, P> extends MenuObject implements IMenuObjectParent, IMenuObjectChild
└── MenuItem extends MenuObject implements IClickable, IMenuObjectChild

// Services
MenuUtil                  // Slot calculations, coordinates, collision detection
VariableResolver          // String template resolution
MenuRenderer              // Convert menu structure to inventory
MenuSession              // Runtime state for player/menu interaction

// Supporting classes
VariableString           // Template string with placeholder resolution
VariableList            // List of VariableStrings with index tracking
MenuItemAction          // Click action definition
DisplayStrategy         // Pluggable rendering strategies
MenuStateListener       // Event observer interface
```

---

## Common Operations

### Creating a Menu

```java
Menu menu = new Menu("Main Menu")
  .setHeight(4)
  .addChildren(
    new MenuSection("Header")
      .setWidth(9).setHeight(1)
      .setPosition(Position.STATIC)
      .addChildren(
        new MenuItem("Title")
          .setMaterial(Material.DIAMOND)
          .setName(new VariableString("Welcome $player.getName$"))
      ),
    new MenuSection("Content")
      .setWidth(9).setHeight(2)
      .setListMode(ListMode.GRID)
      .addChildren(item1, item2, item3, item4)
  );
```

### Calculating Slots for a Section

```java
MenuSection section = new MenuSection("Grid")
  .setStartX(2).setStartY(1)
  .setWidth(5).setHeight(2)
  .setAlignHorizontal(AlignHorizontal.LEFT)
  .setAlignVertical(AlignVertical.TOP);

Set<Integer> occupiedSlots = MenuUtil.calculateSlots(
  2, 1,           // startX, startY
  5, 2,           // width, height
  AlignVertical.TOP,
  AlignHorizontal.LEFT
);
// Result: slots 11, 12, 13, 14, 15, 20, 21, 22, 23, 24
```

### Adding Click Handlers

```java
MenuItem button = new MenuItem("Action Button")
  .setMaterial(Material.EMERALD)
  .addAction(clickEvent -> {
    Player player = (Player) clickEvent.getWhoClicked();
    player.sendMessage("Button clicked!");
  })
  .addAction(clickEvent -> {
    // Update menu state
    menu.updateVariable("counter", 1);
  });
```

### Rendering a Menu to Player

```java
MenuSession session = new MenuSession(player, menu);
MenuRenderer renderer = new MenuRenderer();
Inventory inventory = renderer.render(menu, session);
player.openInventory(inventory);
```

### Updating Menu Content

```java
// For VariableString changes (efficient lore update)
MenuItem item = menu.findItem("title");
item.updateLore(session);  // Only lore lines updated

// For complete item change (full ItemStack recreation)
MenuItem newItem = new MenuItem("New Title");
menu.replaceItem(oldItem, newItem);
session.updateDisplay();
```

---

## Key Enumerations

### Position
- `STATIC`: Fixed position relative to menu
- `RELATIVE`: Position relative to parent boundaries
- `ABSOLUTE`: Position from container origin

### Alignment
- **Vertical**: TOP, CENTER, BOTTOM
- **Horizontal**: LEFT, CENTER, RIGHT

### Display
- `DISPLAY`: Render normally
- `HIDE`: Don't render but take up space
- `DISABLED`: Grayed out
- `HIGHLIGHT`: Emphasized/glowing

### Other
- **Priority**: LOW, MEDIUM, HIGH (render order for overlapping)
- **Growth**: STATIC (fixed), DYNAMIC (expands)
- **ListMode**: DEFAULT, LINEAR, GRID
- **Overflow**: SCROLL, HIDE, WRAP

---

## Performance Tips

1. **Cache VariableString results**
   - Resolved strings are cached in VariableString object
   - Avoid re-resolving in tight loops

2. **Batch inventory updates**
   - Collect dirty items, update all at once
   - Don't call `inventory.setItem()` multiple times

3. **Lazy ItemStack creation**
   - Only build ItemStack when actually displaying
   - Don't pre-create all possible variants

4. **Use async rendering for complex menus**
   - Calculate layouts off main thread
   - Apply updates back on main thread using scheduler

5. **Reuse menu definitions**
   - Create menu template once, render multiple times
   - Immutable definitions = thread-safe

---

## Debugging Checklist

- [ ] Menu validates without errors (`MenuValidator`)
- [ ] Slot calculations don't exceed inventory bounds
- [ ] No slot collisions between sections
- [ ] VariableStrings have valid syntax (only $...$ patterns)
- [ ] All clickable items have handlers registered
- [ ] Background item is defined
- [ ] Display slots are correctly assigned to items
- [ ] Priority ordering matches visibility expectation
- [ ] MenuSession has all necessary context variables
- [ ] No memory leaks (listeners are unregistered on menu close)

---

## Common Pitfalls

| Issue | Cause | Solution |
|-------|-------|----------|
| ItemStack shows `null` in menu | Lazy creation hasn't been triggered | Call `getItemStack()` before rendering |
| Lore not updating | Full ItemStack needed, not just lore update | Check if non-description properties changed |
| Slot collision not detected | Sections not validated before render | Call `MenuValidator.validate()` |
| VariableString returns `null` | Placeholder path is invalid | Log and test variable resolution separately |
| Memory leak on menu close | Click listeners not unregistered | Implement cleanup in MenuSession.close() |
| Click handler not firing | Handler registered for wrong click type | Verify ClickType matches (LEFT, RIGHT, SHIFT+LEFT, etc.) |
| Menu too slow to render | No batching or async rendering | Profile with large menus, implement optimizations |

---

## Integration Checklist

### Before Implementation
- [ ] Review REQUIREMENTS_INVENTORY_MENU.md (sections 1-6)
- [ ] Review ARCHITECTURE_DESIGN.md (sections 1-3)
- [ ] Understand composite pattern and slot calculation strategy

### During Implementation
- [ ] Phase 1: Core framework (Menu, MenuSection, MenuItem, MenuUtil)
- [ ] Phase 2: Variable system (VariableString, resolution)
- [ ] Phase 3: Interaction (clicks, actions)
- [ ] Phase 4: Advanced features (overflow, animations, etc.)
- [ ] Phase 5: Optimization and testing

### After Implementation
- [ ] Unit tests for slot calculations
- [ ] Integration tests for full rendering pipeline
- [ ] Performance tests with 1000+ items
- [ ] Thread safety tests (concurrent clicks)
- [ ] Memory leak checks
- [ ] Documentation and examples

---

## Related Documentation

- **Requirements**: See REQUIREMENTS_INVENTORY_MENU.md for complete feature list
- **Architecture**: See ARCHITECTURE_DESIGN.md for design patterns and optimization strategies
- **Implementation**: (Forthcoming) Step-by-step development guide
- **Legacy Source**: Repository/knk-legacy-plugin/src/main/java/net/knightsandkings/menu/

---

## Questions & Troubleshooting

### "Why composite pattern instead of flat structure?"
- Allows nested sections (sections within sections)
- Recursive rendering is elegant and maintainable
- Matches web DOM model that players might be familiar with

### "How do I prevent slot collisions?"
- Use MenuValidator.validate() before rendering
- Validator checks all sections fit within bounds
- It detects overlapping sections and reports errors

### "Can I use NMS (net.minecraft) code?"
- **No** - use only Bukkit/Paper API and Adventure
- All NMS code from legacy (PacketPlayOut*) must be reimplemented using Bukkit API only

### "How do I handle large menus (500+ items)?"
- Use pagination (multiple menu pages)
- Implement scrolling via Overflow.SCROLL
- Render asynchronously for complex calculations
- Use object pooling for common items

### "Should I store menus in database?"
- Make it optional (can store in YAML or memory)
- Legacy required database, v2 should not
- Consider adding persistence layer as separate module

---

## Legacy vs v2 Comparison

| Aspect | Legacy | v2 Recommendation |
|--------|--------|------------------|
| **Spigot Version** | 1.8, 1.21_R2 with NMS | Paper 1.20+ with Bukkit API only |
| **Text API** | ChatColor | Adventure API |
| **Storage** | Required database (DAO) | Optional, YAML-first approach |
| **Threading** | Sync rendering | Async rendering pipeline |
| **Event System** | None | Observer pattern (listeners) |
| **Testing** | Limited | Comprehensive unit + integration |
| **Performance** | Good for <200 items | Optimized for 1000+ items |
| **NMS Usage** | Reflection-heavy (tab layout) | None - pure Bukkit API |

---

## Next Steps

1. **Read Full Documentation**
   - REQUIREMENTS_INVENTORY_MENU.md (complete feature spec)
   - ARCHITECTURE_DESIGN.md (design patterns and optimization)

2. **Review Legacy Source Code**
   - Focus on MenuSection.java and MenuItem.java
   - Understand slot calculation algorithm
   - Study variable resolution mechanism

3. **Design Phase**
   - Create detailed class diagrams
   - Plan interface boundaries
   - Document data flow

4. **Implementation Phase**
   - Start with Phase 1 (core framework)
   - Write tests as you go
   - Profile performance early

5. **Integration**
   - Connect to UsersQueryApi for player context
   - Integrate with CacheManager
   - Broadcast events to listeners

---

**Questions?** Refer to the full documentation or the legacy source code for implementation patterns.
