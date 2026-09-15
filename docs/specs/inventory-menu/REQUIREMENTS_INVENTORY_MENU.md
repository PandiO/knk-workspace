# Knights & Kings Inventory Menu System - Requirements Document

**Version:** 1.0  
**Date:** January 17, 2026  
**Status:** Analysis & Planning  
**Author:** Legacy System Analysis

---

## Executive Summary

The legacy Knights & Kings plugin implemented a sophisticated, programmable inventory menu system that provides:
- Hierarchical menu composition (Menu → MenuSection → MenuItem)
- Dynamic layout and positioning with alignment controls
- Variable resolution system for dynamic content rendering
- Overflow handling and scrolling
- Dropdown and interactive component support
- Display priorities and growth modes

This document analyzes the legacy architecture and provides requirements for implementing a modern version in the knk-plugin-v2 (Paper 1.20+).

---

## 1. System Overview

### 1.1 Architecture Pattern

The legacy system uses a **composite hierarchical pattern**:

```
Menu (root container)
├── MenuSection (logical grouping)
│   ├── MenuItem (individual item/button)
│   ├── MenuItem (individual item/button)
│   └── MenuSection (nested section)
│       └── MenuItem (item in nested section)
└── MenuSection (another grouping)
    └── MenuItem
```

### 1.2 Core Design Principles

- **Composition over inheritance**: Objects are composed into containers rather than deeply nested
- **Virtual grid-based layout**: 9-wide × N-tall slot system matching Minecraft inventory dimensions
- **Declarative configuration**: Menus defined through code with chainable builder pattern
- **Separation of concerns**: Menu structure, display logic, and interaction handling are separate
- **Parent-child relationships**: Bidirectional parent-child tracking for context and constraints

---

## 2. Functional Requirements

### 2.1 Menu Composition

#### FR-2.1.1: Menu Class
- Represents the top-level container for inventory menus
- Properties:
  - `menuName`: Variable string (supports dynamic resolution)
  - `height`: Configurable row count (default: 3 rows = 27 slots)
  - `growth`: Growth mode (STATIC, DYNAMIC)
  - `width`: Always 9 slots (standard Minecraft inventory width)
  - `backgroundItem`: Fill material for empty slots (default: white stained glass pane)
- Methods:
  - `addChildren()`: Add menu sections to menu
  - `removeChildren()`: Remove menu sections
  - `setChildren()`: Replace all children
  - `findChild(name)`: Locate section by name

**Acceptance Criteria:**
- Menu can be instantiated with custom name and dimensions
- Menu supports 1 to N sections (no hard limit)
- Background material is configurable and respects fill slots

#### FR-2.1.2: MenuSection Class
- Represents logical groupings of menu items
- Bidirectional parent-child relationships
- Properties:
  - `name`: Unique identifier within parent
  - `width`: Section width in slots (1-9)
  - `height`: Section height in slots (1-5+)
  - `overflow`: Behavior when content exceeds bounds (SCROLL, HIDE, WRAP)
  - `listMode`: How children are arranged (DEFAULT, LINEAR, GRID)
  - `position`: Layout mode (STATIC, RELATIVE, ABSOLUTE)
  - `displaySlot`: Starting slot for placement
  - `alignVertical`: Alignment (TOP, CENTER, BOTTOM)
  - `alignHorizontal`: Alignment (LEFT, CENTER, RIGHT)
  - `priority`: Render priority (LOW, MEDIUM, HIGH)
  - `dropdownButtons`: Optional dropdown menu items

#### FR-2.1.3: MenuItem Class
- Represents clickable inventory items
- Properties:
  - `name`: Variable string (dynamic text resolution)
  - `description`: List of variable strings for lore (first items match VariableString indexes for efficient updates)
  - `material`: Bukkit Material
  - `amount`: Stack size
  - `enchantments`: HashMap of enchantment level mappings
  - `chatColorName`: Display name color
  - `chatColorDescription`: Lore color
- Methods:
  - `createItemStack()`: Build Bukkit ItemStack with current values
  - `getName()`: Get resolved name
  - `getDescription()`: Get resolved descriptions

### 2.2 Layout and Positioning

#### FR-2.2.1: Coordinate System
- 2D grid coordinate system (x, y)
- Origin at top-left (0, 0)
- X-axis: 0-8 (9 slots per row)
- Y-axis: 0-N (number of rows)
- Convert between slot index (0-53 for 6 rows) and coordinates

#### FR-2.2.2: Slot Calculation
- Calculate slot set based on:
  - Start position (startSlot or x, y coordinates)
  - Width and height (in slots)
  - Alignment rules (vertical and horizontal)
  - Growth mode (static vs. dynamic expansion)

**Service: MenuUtil**
- `calculateSlots(startSlot, width, height, alignVert, alignHori)`: Return set of affected slots
- `getXCoordinateAbsolute(slot)`: Convert slot to X coordinate
- `getYCoordinateAbsolute(slot)`: Convert slot to Y coordinate
- `getSlotByCoordinates(x, y)`: Convert coordinates to slot
- `getOverlapByMenuSection(section, sections[])`: Detect overlapping sections

#### FR-2.2.3: Position Modes
- **STATIC**: Fixed position, does not move
- **RELATIVE**: Position relative to parent boundaries
- **ABSOLUTE**: Positioned from container origin

#### FR-2.2.4: Alignment Options
- **Vertical**: TOP, CENTER, BOTTOM
- **Horizontal**: LEFT, CENTER, RIGHT
- **Content**: Control child element alignment within section

#### FR-2.2.5: Growth Modes
- **STATIC**: Fixed dimensions, no expansion
- **DYNAMIC**: Expands based on content and available space

### 2.3 Variable Resolution System

#### FR-2.3.1: VariableString Class
- Strings containing placeholders that resolve at runtime
- Format: `$methodName$` or `$propertyName$`
- Example: `"Player: $player.getName$"` → `"Player: John"`
- Properties:
  - `pattern`: Template string with placeholders
  - `result`: Last resolved value (cached for efficient lookup in ItemStack lore)

**Key capability**: Support nested method chains and property access

#### FR-2.3.2: VariableList Class
- List wrapper for VariableString objects
- Maintains index correspondence between VariableString objects and their resolved results in ItemStack lore
- Enables efficient lore updates without full ItemStack reconstruction

#### FR-2.3.3: Resolution Scope
- Access to player context
- Access to menu session data
- Access to menu/section/item properties
- Support for utility functions and formatters

### 2.4 Display and Rendering

#### FR-2.4.1: Display Modes (Enumeration)
- **DISPLAY**: Render normally
- **HIDE**: Do not render (still takes up space)
- **DISABLED**: Render as disabled/grayed out
- **HIGHLIGHT**: Render with emphasis/glow

#### FR-2.4.2: Render Priority
- **LOW**: Render last (undermost)
- **MEDIUM**: Render after LOW, before HIGH
- **HIGH**: Render first (topmost, overlaps others)
- Controls layering when sections overlap

#### FR-2.4.3: Overflow Handling
- **SCROLL**: Content scrollable within section bounds
- **HIDE**: Excess content is hidden
- **WRAP**: Content wraps to next row within section

#### FR-2.4.4: List Modes
- **DEFAULT**: Items appear in order, left to right, top to bottom
- **LINEAR**: Single column or row layout
- **GRID**: Fill grid based on dimensions

#### FR-2.4.5: Display Slot Assignment
- Automatic slot assignment for menu items within sections
- Respects section boundaries
- Handles overflow modes
- Prevents slot collisions

### 2.5 Interaction & Click Handling

#### FR-2.5.1: IClickable Interface
- MenuItem implements click handling
- Properties:
  - `clickType`: ClickType (LEFT, RIGHT, SHIFT_LEFT, etc.)
  - `actions`: List of MenuItemAction instances
  - `condition`: Optional click condition (predicate)
- Methods:
  - `onClick(ClickType, Player)`: Handle click event
  - `canClick(ClickType, Player)`: Validate click is allowed

#### FR-2.5.2: Action System
- MenuItem can trigger one or more actions on click
- Action types:
  - RunnableAction: Execute custom logic
  - MenuItemAction: Data-driven action configuration
  - NavigationAction: Open another menu/section
  - StateChangeAction: Update menu state

#### FR-2.5.3: Dropdown Functionality
- Optional dropdown menus attached to sections
- Triggered on specific menu interaction
- Support for multi-level dropdowns
- Cancel/close dropdown via click or escape

### 2.6 Dynamic Content & Blinking

#### FR-2.6.1: MenuItem Blink (MenuItemBlink class)
- Support for time-based item updates
- Example: Countdown timers, animated items
- Properties:
  - `interval`: Update frequency (ticks)
  - `duration`: Total duration before reset
  - `animationStages`: List of ItemStack variants
- Updates lore values that are VariableStrings with time-based result

#### FR-2.6.2: Time-aware Variables
- VariableString can resolve time-based values
- Example: Remaining time, elapsed time, percentage complete

---

## 3. Non-Functional Requirements

### 3.1 Performance

**NFR-3.1.1: Rendering Performance**
- Menus with up to 200 items should render in <50ms
- ItemStack creation should be optimized (reuse where possible)
- Lore updates should avoid full ItemStack recreation when only text changed

**NFR-3.1.2: Memory Efficiency**
- VariableString result caching to avoid repeated resolution
- Lazy ItemStack creation (build only when displayed)
- Efficient slot calculation using set operations

**NFR-3.1.3: Click Response**
- Click actions should complete within 100ms
- No blocking operations in click handlers
- Async actions must not block inventory rendering

### 3.2 Reliability

**NFR-3.2.1: Slot Collision Detection**
- Prevent menu items/sections from occupying same slot
- Raise validation error or auto-resolve collisions

**NFR-3.2.2: Boundary Validation**
- Validate all positions/sizes are within valid bounds
- Prevent items from rendering outside menu borders
- Log warnings for configuration issues

**NFR-3.2.3: Error Handling**
- Graceful handling of invalid variable resolutions
- Safe fallback for missing data
- Detailed logging for debugging

### 3.3 Extensibility

**NFR-3.3.1: Plugin Architecture**
- New action types can be registered
- Custom variable resolvers can be added
- Custom display modes and list modes supported

**NFR-3.3.2: Preset Templates**
- Pre-built menu templates for common patterns:
  - Confirmation dialogs
  - Pagination menus
  - Form-like input screens
  - List browsers with filters

---

## 4. Data Model

### 4.1 Interfaces

```java
// Base interface
IMenuObject<T> {
  T getInstance();
  Long getId();
  String getName();
  List<String> getDescription();
}

// Composition interfaces
IMenuObjectParent<Parent, Child> {
  List<Child> getChildren();
  Parent setChildren(List<Child>);
  Parent addChildren(Child...);
  Parent removeChildren(Child...);
}

IMenuObjectChild<Child, Parent> {
  Parent getParent();
  Child setParent(Parent);
}

// Display/scaling
IScalable<T> {
  int getWidth();
  T setWidth(int);
  int getHeight();
  T setHeight(int);
  Position getPosition();
  T setPosition(Position);
  Priority getPriority();
  T setPriority(Priority);
  Growth getGrowth();
  T setGrowth(Growth);
}

// Interaction
IClickable {
  void onClick(ClickType, Player);
  boolean canClick(ClickType, Player);
}
```

### 4.2 Enumerations

- **Position**: STATIC, RELATIVE, ABSOLUTE
- **AlignVertical**: TOP, CENTER, BOTTOM
- **AlignHorizontal**: LEFT, CENTER, RIGHT
- **Display**: DISPLAY, HIDE, DISABLED, HIGHLIGHT
- **Priority**: LOW, MEDIUM, HIGH
- **Growth**: STATIC, DYNAMIC
- **ListMode**: DEFAULT, LINEAR, GRID
- **Overflow**: SCROLL, HIDE, WRAP
- **ClickType**: LEFT, RIGHT, SHIFT_LEFT, SHIFT_RIGHT, etc.

---

## 5. Integration Points

### 5.1 Paper API Integration
- Adventure API for text formatting and components
- Bukkit Inventory and ItemStack for rendering
- Bukkit events for click detection (InventoryClickEvent)
- Bukkit scheduler for animations and updates

### 5.2 KNK Core Integration
- Player context (UsersQueryApi)
- Cache system (CacheManager) for menu definitions
- Data models from domain layer
- Event broadcasting for menu open/close

### 5.3 Web App Integration
- Menu definitions could be managed via Web API (future)
- Sync menu state with server state
- Support for data-driven menu configuration

---

## 6. Legacy Implementation Analysis

### 6.1 Strengths

1. **Composable Architecture**: Flexible composition allows complex menu layouts
2. **Type Safety**: Generic constraints prevent type mismatches
3. **Variable System**: Elegant solution for dynamic content
4. **Efficient Lore Updates**: Result caching prevents duplicate resolution
5. **Comprehensive Positioning**: Full coordinate system with alignment
6. **Extensible Action System**: Actions are pluggable
7. **Preset Library**: Common menu patterns pre-implemented

### 6.2 Identified Limitations

1. **Spigot Version Specific Code**: Used NMS (net.minecraft) for advanced features
   - `PacketPlayOutPlayerListHeaderFooter` for tab layout
   - CraftPlayer handle access
   - This will not be compatible with modern Paper implementations
   
2. **Repository Dependency**: Tightly coupled to legacy DAO/Repository system
   - Menu definitions stored in database
   - Consider making this optional in v2
   
3. **No Event System**: Menus don't broadcast state changes to listeners
   
4. **Limited Validation**: Slot collision detection exists but incomplete
   
5. **Complex Display Logic**: MenuDisplayed class handles rendering and is difficult to maintain
   - Consider separating rendering engine

---

## 7. Suggested Improvements for v2

### 7.1 Modernization

1. **Remove NMS Dependencies**
   - Use Adventure API exclusively
   - Pure Bukkit/Paper API for all interactions
   - No reflection or CraftBukkit access needed

2. **Async Rendering**
   - Render menus asynchronously to avoid blocking
   - Use Paper's scheduler for smooth updates
   - Batch ItemStack updates

3. **Observer Pattern**
   - Add MenuStateListener interface
   - Broadcast menu open/close/update events
   - Allow external systems to react to menu changes

### 7.2 Functional Enhancements

1. **Validation Framework**
   - Comprehensive pre-render validation
   - Detect and resolve slot collisions
   - Configuration warnings

2. **CSS-Like Styling**
   - Define menu appearance in YAML/JSON
   - Separate styling from logic
   - Easier customization without code changes

3. **Keyboard/Controller Support**
   - Navigate menus using arrow keys
   - Tab between clickable items
   - Enter to select, Esc to close

4. **Menu Transitions**
   - Smooth animations when switching menus
   - Fade, slide, or zoom effects
   - Configureable transition duration

5. **Accessibility**
   - Support for screen readers (text-based mode)
   - High contrast mode
   - Tooltips for all items

### 7.3 Architecture Improvements

1. **Plugin System**
   - Renderer plugins for different display modes
   - Layout calculation plugins
   - Variable resolver plugins

2. **Caching Strategy**
   - Cache compiled menu definitions
   - Cache rendered ItemStacks
   - Invalidate cache on model changes

3. **Persistence**
   - Optional database storage
   - YAML serialization for simple menus
   - Version migration path

4. **Testing Infrastructure**
   - Unit tests for slot calculations
   - Mock inventories for rendering tests
   - Performance benchmarks

---

## 8. Implementation Roadmap

### Phase 1: Core Framework (Priority: High)
- [ ] Implement Menu, MenuSection, MenuItem classes
- [ ] Build coordinate system and slot calculation (MenuUtil)
- [ ] Implement positioning and alignment
- [ ] Basic rendering to Bukkit inventory

### Phase 2: Variable System (Priority: High)
- [ ] Implement VariableString and VariableList
- [ ] Build variable resolution engine
- [ ] Integration with player/game context
- [ ] Efficient lore updates

### Phase 3: Interaction (Priority: High)
- [ ] IClickable interface and click handling
- [ ] Action system implementation
- [ ] Dropdown functionality
- [ ] Menu navigation

### Phase 4: Advanced Features (Priority: Medium)
- [ ] Overflow handling (scroll, wrap)
- [ ] Blinking/animation support
- [ ] Display modes and priorities
- [ ] Preset templates

### Phase 5: Polish & Optimization (Priority: Medium)
- [ ] Performance optimization
- [ ] Comprehensive validation
- [ ] Event system
- [ ] Documentation and examples

### Phase 6: Future Enhancements (Priority: Low)
- [ ] Web API integration
- [ ] CSS-like styling system
- [ ] Keyboard navigation
- [ ] Plugin system for extensibility

---

## 9. Risk Assessment

### 9.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Complex slot calculations have bugs | High | Medium | Comprehensive unit tests, property-based testing |
| Performance degradation with large menus | High | Low | Profiling early, batching updates, caching |
| Variable resolution circular dependencies | Medium | Low | Dependency graph validation, recursion limits |
| Memory leaks in click handlers | Medium | Low | Proper listener unregistration, weak references |

### 9.2 Design Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|-----------|
| Architecture limits scalability | High | Low | Modular design, plugin system planned |
| Breaking changes needed during implementation | Medium | Medium | Prototype before full implementation |
| Insufficient separation of concerns | Medium | Medium | Clear interface boundaries, composition over inheritance |

---

## 10. Glossary

- **MenuObject**: Base class for menu components (Menu, MenuSection, MenuItem)
- **MenuSection**: Logical grouping of menu items with positioning/sizing
- **MenuItem**: Individual clickable inventory item
- **Slot**: Single position in Minecraft inventory (0-53 for 6 rows)
- **VariableString**: String template with runtime variable resolution
- **IClickable**: Interface for components that respond to player clicks
- **Overflow**: Behavior when menu content exceeds section bounds
- **Priority**: Layering order for overlapping menu elements
- **Growth Mode**: Whether menu dimensions are fixed or dynamic

---

## 11. Reference Specifications

### Legacy Implementation Details
- **Language**: Java
- **Build System**: Gradle (knk-plugin-v2)
- **Minecraft Version**: 1.20+ (Paper)
- **Legacy Spigot Version**: 1.21_R2 (not used in v2)
- **Dependencies**: Adventure API, Bukkit/Paper API

### Related Documentation
- See: [docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md](../project-overview/IMPLEMENTATION_ROADMAP.md)
- See: [docs/specs/api/README.md](../api/README.md) for API integration points
