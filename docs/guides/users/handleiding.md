---
status: stale
last_updated: 2018-10-03
related_repo: knk-v1-archive
---

# Handleiding (v1 manual)

> `Handleiding.docx` — a short v1-era procedure guide (Dutch), covering how staff registered items as sellable in shops. Likely no longer accurate against the current v3 item/shop system; kept as historical reference for how the mechanic used to work.

---

## Procedure to make an item sellable in shops

Rename the item either to a colorless name or a colored name (color-code is &), use "/rename" to rename the item.

Register the item into the system by using the "/product set" command. Properties needed for registering the item are: the grade (1–5), the category of the item, the minimum price, the maximum price, a description and a name. For the name, use the display-name without spaces.

If every property of the item is filled out correctly in the command, the item is now registered.

Possible error messages:
- The itemTypeID is not in the database: please notify Pandi.
- The materialID is not in the database: please notify Pandi.

## Procedure to add an item to a property to sell it

1. Make sure you are in owner-mode ("/om").
2. Open your personal menu ("/menu").
3. In the owner-mode options, find the NameTag called "ShopItems Manager", click it.
4. Click an item-category you want to add to a property.
5. Find the item in the list of items you want to add, click it.
6. Find the property in the list of applicable properties to add the item to, and click it.
