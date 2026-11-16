# knk-api-endpoint templates

Skeletons cut down from the Tag pipeline on knk-web-api `main`. Replace `Widget`/`Widgets`, keep the shape, and check
the real file when in doubt.

## 1. Controller (dashboard type, content area)

From `Controllers/TagsController.cs`:

```csharp
namespace KnKWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    // Every write (incl. POST search) needs knk.admin.content or the game server; reads need the type's read nodes.
    [RequireServiceOrPermissionForWrites(StaffPermissions.ManageContent)]
    [DashboardReads("Widget")]
    public class WidgetsController : ControllerBase
    {
        private readonly IWidgetService _service;

        public WidgetsController(IWidgetService service) => _service = service;

        [HttpGet("{id:int}", Name = "GetWidgetById")]
        public async Task<IActionResult> GetById(int id)
        {
            var item = await _service.GetByIdAsync(id);
            return item == null ? NotFound() : Ok(item);
        }

        [RequireDashboardChange("Widget")]
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] WidgetCreateDto dto)
        {
            if (dto == null) return BadRequest();
            try
            {
                var created = await _service.CreateAsync(dto);
                return CreatedAtRoute("GetWidgetById", new { id = created.Id }, created);
            }
            catch (ArgumentException ex) { return BadRequest(ex.Message); }
        }

        // Area node AND knk.admin.delete (dashboard access model, PandiO/knk-workspace#280).
        [RequireServiceOrPermission(StaffPermissions.Delete)]
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            try { await _service.DeleteAsync(id); return NoContent(); }
            catch (KeyNotFoundException) { return NotFound(); }
            catch (ArgumentException ex) { return BadRequest(ex.Message); }
            catch (InvalidOperationException ex) when (!DeleteConstraintExceptionFilter.IsConstraintFailure(ex))
            {
                return Conflict(new { code = "BusinessRuleViolation", message = ex.Message });
            }
        }

        [HttpPost("search")]
        public async Task<ActionResult<PagedResultDto<WidgetListDto>>> Search([FromBody] PagedQueryDto query)
            => Ok(await _service.SearchAsync(query));
    }
}
```

## 2. A single action outside the dashboard

```csharp
// PandiO/knk-workspace#<n>: <why this caller may do this>.
[RequireServiceOrPermission(StaffPermissions.ManageWorld)]
[HttpPost("{id:int}/archive")]
public async Task<IActionResult> Archive(int id) { ... }

// The game server only.
[RequirePluginService]
[HttpPost("report")]
public async Task<IActionResult> Report([FromBody] WidgetReportDto dto) { ... }
```

Then pin it: a write needs only its rule (EndpointAccessRulesTests checks that it has one); a read goes into
`ReadAccessRulesTests.Pinned` with its category code, for example `["WidgetsController.GetStatus"] = "D"`.

## 3. Service test

From `Tests/knkwebapi_v2.Tests/Services/GradeServiceTests.cs`:

```csharp
public class WidgetServiceTests
{
    private readonly Mock<IWidgetRepository> _repo = new();
    private readonly IMapper _mapper =
        new MapperConfiguration(cfg => cfg.AddProfile<WidgetMappingProfile>()).CreateMapper();

    private WidgetService Service() => new(_repo.Object, _mapper);

    [Fact]
    public async Task Create_WithoutAName_IsRefused()
    {
        await Assert.ThrowsAsync<ArgumentException>(() => Service().CreateAsync(new WidgetCreateDto { Name = " " }));
        _repo.Verify(r => r.AddAsync(It.IsAny<Widget>()), Times.Never);
    }

    [Fact]
    public async Task Update_OfAMissingWidget_IsNotFound()
    {
        _repo.Setup(r => r.GetByIdAsync(9)).ReturnsAsync((Widget?)null);
        await Assert.ThrowsAsync<KeyNotFoundException>(() => Service().UpdateAsync(9, new WidgetUpdateDto { Id = 9, Name = "x" }));
    }
}
```

## 4. Pinned access entries for a new dashboard type

```csharp
// ReadAccessRulesTests.Pinned
["WidgetsController.GetAll"] = "F Widget",
["WidgetsController.GetById"] = "F Widget",
["WidgetsController.Search"] = "F Widget",

// DashboardChangeAccessRulesTests.ChangeActions
("WidgetsController", "Create", "Widget"), ("WidgetsController", "Update", "Widget"),

// DeleteAccessRulesTests.PrimaryDeletes
["Widget"] = "WidgetsController.Delete",
```
