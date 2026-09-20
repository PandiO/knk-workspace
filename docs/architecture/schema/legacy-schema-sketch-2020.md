---
status: stale
last_updated: 2020-03-25
related_repo: knk-v1-archive
---

# Legacy schema sketch (pre-Hibernate, 2020)

> `K&K_Database` — a hand-written pre-Hibernate schema sketch from the v1→v2 transition period. Notable for schema-archaeology value: the current gate-structure work (see `docs/specs/gate-structure-animation/`) traces back to a `Gate` table this old.

---

```sql
CREATE TABLE Structure (
    ID int NOT NULL Primary Key Auto_Increment,
    Name VARCHAR(250) NOT NUll,
    StreetID int NOT NULL,
    StreetNumber int,
    TownID int NOT NULL,
    DistrictID int NOT NULL,
    SpawnpointID int
);

Create TABLE House2 (
    ID int NOT NUll PRIMARY KEY AUTO_INCREMENT,
    StructureID int NOT Null,
    Price int Not NUll,
    OwnerID int,
    CONSTRAINT FK_StructureID FOREIGN KEY (StructureID) REFERENCES Structure(ID),
    CONSTRAINT FK_OwnerID FOREIGN KEY (OwnerID) REFERENCES Player(ID)
    );

Create TABLE Property2 (
    ID int NOT Null PRIMARY KEY,
    Price int NOT Null,
    Income int Not Null,
    Level int NOT null,
    Contribution int NOT null,
    NpcID int,
    NpcSpawnpointID int NOT Null,
    CategoryID int Not NUll,
    OwnerID int,
    FOREIGN KEY (ID) REFERENCES Structure(ID),
    FOREIGN KEY (OwnerID) REFERENCES Player(ID)
    );

CREATE TABLE Gate (
    ID int NOT NuLL PRIMARY KEY,
    MaterialID int NOT Null,
    FaceDirection VARCHAR(250) NOt NULL,
    OriginalHealth double NOT Null,
    CurrentHealth double Not NULL,
    Closed boolean Not Null DEFAULT false,
    FOREIGN KEY (ID) REFERENCES Structure(ID),
    FOREIGN KEY (MaterialID) REFERENCES Materials(ID)
    );
```

(Typos/inconsistent capitalization in column definitions — e.g. `NOT NUll`, `NuLL` — preserved verbatim from the original sketch.)
