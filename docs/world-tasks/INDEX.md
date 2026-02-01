# WorldTask Feature Documentation Index

## Quick Navigation

### 🚀 Getting Started
- **[README.md](README.md)** - Feature overview, key concepts, quick start guide
- **[HANDLER_ACTIVATION_GUIDE.md](HANDLER_ACTIVATION_GUIDE.md)** - How to activate handlers from web app (ANSWER TO YOUR QUESTION)

### 📋 Specification & Requirements
- **[SPEC_WORLDTASK.md](SPEC_WORLDTASK.md)** - Technical specification (data models, schemas, DTOs)
- **[REQUIREMENTS_WORLDTASK.md](REQUIREMENTS_WORLDTASK.md)** - Functional and technical requirements

### 🏗️ Architecture & Design
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture, data flow, component relationships
- **[IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)** - What's implemented, what's planned

### 🔌 API & Integration
- **[API_CONTRACT.md](API_CONTRACT.md)** - Complete REST API endpoint reference with examples
- **[HANDLER_DEVELOPMENT_GUIDE.md](HANDLER_DEVELOPMENT_GUIDE.md)** - How to create new task handlers

---

## Document Purposes

### README.md
**Purpose:** High-level overview and entry point
**Audience:** Project leads, architects, new team members
**Contains:**
- Feature overview and key concepts
- Architecture layers overview
- Commits reference
- Related documents list
- Quick start scenario

**Read if:** You want a quick understanding of what WorldTask does

---

### SPEC_WORLDTASK.md
**Purpose:** Technical specification for implementers
**Audience:** Backend and plugin developers
**Contains:**
- WorldTask entity definition
- Task lifecycle states
- Input/Output JSON schemas for each field type
- API DTOs
- LinkCode generation rules
- Workflow step association logic
- Idempotency and concurrency patterns
- Plugin integration patterns

**Read if:** You need detailed technical specifications for implementation

---

### REQUIREMENTS_WORLDTASK.md
**Purpose:** Functional and technical requirements documentation
**Audience:** Developers, QA, project managers
**Contains:**
- FR-1 through FR-5: Functional requirements
- TR-1 through TR-5: Technical requirements
- NFR-1 through NFR-4: Non-functional requirements
- Implementation priorities (Phase 1, 2, 3)

**Read if:** You need to understand what the feature must do

---

### ARCHITECTURE.md
**Purpose:** System design and data flow documentation
**Audience:** Architects, senior developers
**Contains:**
- High-level data flow diagram
- Component architecture for each layer (Web App, API, Plugin)
- Data models and relationships
- State diagrams
- Synchronization points between systems
- Error handling and recovery flows
- Performance considerations

**Read if:** You need to understand how components interact

---

### API_CONTRACT.md
**Purpose:** REST API endpoint reference
**Audience:** Frontend developers, plugin developers, API consumers
**Contains:**
- Complete endpoint definitions with HTTP methods and paths
- Request/response examples for each endpoint
- DTOs and data types
- OutputJson schemas by field type
- Error codes and meanings
- Rate limiting and caching guidelines
- Complete workflow example

**Read if:** You need to call the API or understand its contract

---

### HANDLER_DEVELOPMENT_GUIDE.md
**Purpose:** Tutorial for creating new task handlers
**Audience:** Plugin developers extending the system
**Contains:**
- Handler interface contract
- Step-by-step handler implementation guide
- LocationTaskHandler as complete example
- Best practices and patterns
- Testing guidelines
- Troubleshooting guide

**Read if:** You want to create a new handler (e.g., for a new field type)

---

### HANDLER_ACTIVATION_GUIDE.md
**Purpose:** How to activate handlers from the web app (YOUR QUESTION)
**Audience:** Web app developers, integrators
**Contains:**
- Complete activation flow (9 steps)
- FieldName property explanation
- Handler-to-fieldName mapping table
- Handler discovery mechanism
- What data to provide from web app
- How to extend with new handlers
- Troubleshooting common issues

**Read if:** You want to know what types/IDs the web app needs to provide

---

### IMPLEMENTATION_CHECKLIST.md
**Purpose:** Track implementation status across all systems
**Audience:** Project managers, developers, QA
**Contains:**
- Feature checklist organized by system
- What's implemented (Phase 1: Complete)
- What's in-progress or planned (Phase 2, 3)
- Testing requirements
- Deployment checklist
- Rollback plan

**Read if:** You need to track implementation progress or verify feature completeness

---

## Common Workflows

### "I'm implementing the WorldTask feature"
1. Start with [README.md](README.md) for overview
2. Read [SPEC_WORLDTASK.md](SPEC_WORLDTASK.md) for detailed specs
3. Reference [API_CONTRACT.md](API_CONTRACT.md) for endpoints
4. Use [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md) to track progress

### "I need to create a new handler"
1. Review [HANDLER_DEVELOPMENT_GUIDE.md](HANDLER_DEVELOPMENT_GUIDE.md)
2. Reference LocationTaskHandler in the guide
3. Check [SPEC_WORLDTASK.md](SPEC_WORLDTASK.md) for payload schemas
4. Test against [API_CONTRACT.md](API_CONTRACT.md) endpoints

### "I need to activate a handler from the web app"
1. Go directly to [HANDLER_ACTIVATION_GUIDE.md](HANDLER_ACTIVATION_GUIDE.md)
2. See the mapping table of FieldNames to handlers
3. Check section "What to Provide from Web App"
4. Reference code examples in the document

### "I need to understand the system architecture"
1. Start with [ARCHITECTURE.md](ARCHITECTURE.md)
2. Review data flow diagrams and component relationships
3. Check [SPEC_WORLDTASK.md](SPEC_WORLDTASK.md) for data models
4. Reference [API_CONTRACT.md](API_CONTRACT.md) for integration points

### "I need to troubleshoot a WorldTask issue"
1. Check "Troubleshooting" section in [HANDLER_ACTIVATION_GUIDE.md](HANDLER_ACTIVATION_GUIDE.md)
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) error handling section
3. Check [HANDLER_DEVELOPMENT_GUIDE.md](HANDLER_DEVELOPMENT_GUIDE.md) for handler-specific issues
4. Review logs against [SPEC_WORLDTASK.md](SPEC_WORLDTASK.md) state transitions

---

## Key Concepts Summary

| Concept | Definition | Find Details |
|---------|-----------|---------------|
| **WorldTask** | A task that captures world-bound data from Minecraft | README.md, SPEC_WORLDTASK.md |
| **FieldName** | String identifier for task handler (e.g., "Location") | HANDLER_ACTIVATION_GUIDE.md |
| **LinkCode** | 6-char code player uses to claim task in-game | SPEC_WORLDTASK.md, API_CONTRACT.md |
| **Handler** | Java class that executes task-specific logic | HANDLER_DEVELOPMENT_GUIDE.md |
| **StepProgress** | Workflow step tracking (Pending, InProgress, Completed) | ARCHITECTURE.md, SPEC_WORLDTASK.md |
| **OutputJson** | JSON payload with captured data from handler | SPEC_WORLDTASK.md, API_CONTRACT.md |
| **InputJson** | JSON payload with task constraints/configuration | SPEC_WORLDTASK.md, HANDLER_ACTIVATION_GUIDE.md |

---

## Implementation Status (Phase 1: Complete)

✅ **Completed Features:**
- WorldTask CRUD operations
- Claim/Complete/Fail state transitions
- LinkCode generation and validation
- LocationTaskHandler (new)
- WgRegionIdTaskHandler (existing)
- Plugin commands and event listeners
- Web API endpoints (6 endpoints)
- Web app wizard components
- Task monitoring and polling

📋 **In-Progress/Planned (Phase 2+):**
- Advanced validation (parent regions, constraints)
- Task retry logic with backoff
- Task timeouts and auto-cleanup
- Access control enhancements
- Batch operations
- Task history/audit trail

---

## Commits Reference

This documentation is based on analysis of the following commits:

**knk-web-api-v2:**
- `3a64c0d` - Hybrid workflow with task integration
- `b6fdad2` - WorldTask implementation

**knk-web-app:**
- `324fc4b` - Multi-step wizard UI and task monitoring
- `c5d3cf5`, `b7cdc4b` - Improvements and testing

**knk-plugin-v2:**
- `08bb1de` - WorldTask foundation
- `a471b55` - WgRegionIdTaskHandler
- `9164782` - Claiming and execution improvements
- `5286cef` - Region renaming finalization

---

## Document Maintenance

### Version
Current: 1.0 (January 27, 2026)

### When to Update
- When new handlers are created → Update HANDLER_DEVELOPMENT_GUIDE.md and HANDLER_ACTIVATION_GUIDE.md
- When new fields are supported → Update API_CONTRACT.md with new OutputJson schemas
- When Phase 2/3 features are implemented → Update IMPLEMENTATION_CHECKLIST.md
- When API endpoints change → Update API_CONTRACT.md and ARCHITECTURE.md

### How to Update
1. Edit the relevant markdown file
2. Keep section headers consistent
3. Update the index table above if adding new sections
4. Update related document cross-references

---

## Contact & Support

For questions about:
- **Architecture/Design**: See ARCHITECTURE.md and consult senior architects
- **Implementation/Coding**: See HANDLER_DEVELOPMENT_GUIDE.md and SPEC_WORLDTASK.md
- **API/Integration**: See API_CONTRACT.md and HANDLER_ACTIVATION_GUIDE.md
- **Testing/QA**: See IMPLEMENTATION_CHECKLIST.md
- **Feature Requirements**: See REQUIREMENTS_WORLDTASK.md

