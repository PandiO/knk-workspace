package net.knightsandkings.knk.paper.roads;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import net.knightsandkings.knk.core.domain.roads.RoadMaterialRole;
import net.knightsandkings.knk.core.domain.roads.RoadNodeKind;
import net.knightsandkings.knk.core.roads.build.BuildParameters;
import net.knightsandkings.knk.core.roads.build.GateCells;
import net.knightsandkings.knk.core.roads.build.MaskBuilder;
import net.knightsandkings.knk.core.roads.build.NodeMatcher;
import net.knightsandkings.knk.core.roads.build.PassabilityRules;
import net.knightsandkings.knk.core.roads.build.ProfileSet;
import net.knightsandkings.knk.core.roads.build.SkeletonGraph;
import net.knightsandkings.knk.core.roads.build.TileBuildResult;
import net.knightsandkings.knk.core.roads.build.TileBuilder;
import net.knightsandkings.knk.core.roads.survey.ProposedProfile;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.RandomAccessFile;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.Optional;
import java.util.function.Predicate;
import java.util.zip.GZIPInputStream;
import java.util.zip.InflaterInputStream;

/**
 * KNG-27 offline replay: runs the real TileBuilder on copies of the dev world's region files and the build inputs
 * exported from the dev DB (see README.md next to this file). Copy into knk-paper/src/test/java/net/knightsandkings/knk/paper/roads/
 * to use; skipped unless KNK_REPLAY_DIR points at a folder with region/ and replay/ inside.
 */
class ReplayScratchTest {
    static final String SCRATCH = Optional.ofNullable(System.getenv("KNK_REPLAY_DIR")).map(d -> d.endsWith("/") ? d : d + "/").orElse("");
    static int[] FOCUS = {1370, 1460, -600, -495}; // minX maxX minZ maxZ

    // ---- NBT / Anvil ------------------------------------------------------------------------
    static Object readTag(DataInputStream in, int type) throws IOException {
        switch (type) {
            case 1: return in.readByte();
            case 2: return in.readShort();
            case 3: return in.readInt();
            case 4: return in.readLong();
            case 5: return in.readFloat();
            case 6: return in.readDouble();
            case 7: { byte[] b = new byte[in.readInt()]; in.readFully(b); return b; }
            case 8: return in.readUTF();
            case 9: { int t = in.readByte(); int n = in.readInt(); List<Object> l = new ArrayList<>(); for (int i = 0; i < n; i++) l.add(readTag(in, t)); return l; }
            case 10: { Map<String, Object> m = new HashMap<>(); while (true) { int t = in.readByte(); if (t == 0) return m; String k = in.readUTF(); m.put(k, readTag(in, t)); } }
            case 11: { int[] a = new int[in.readInt()]; for (int i = 0; i < a.length; i++) a[i] = in.readInt(); return a; }
            case 12: { long[] a = new long[in.readInt()]; for (int i = 0; i < a.length; i++) a[i] = in.readLong(); return a; }
            default: throw new IOException("tag " + type);
        }
    }

    /** One chunk: per section y (blockY>>4) the palette and packed data. */
    static final class Chunk {
        final Map<Integer, String[]> palettes = new HashMap<>();
        final Map<Integer, long[]> data = new HashMap<>();

        String at(int lx, int y, int lz) {
            int sy = Math.floorDiv(y, 16);
            String[] pal = palettes.get(sy);
            if (pal == null) return "AIR";
            if (pal.length == 1) return pal[0];
            long[] d = data.get(sy);
            int bits = Math.max(4, 32 - Integer.numberOfLeadingZeros(pal.length - 1));
            int perLong = 64 / bits;
            int i = ((y & 15) * 16 + lz) * 16 + lx;
            long word = d[i / perLong];
            int v = (int) ((word >>> ((i % perLong) * bits)) & ((1L << bits) - 1));
            return v < pal.length ? pal[v] : "AIR";
        }
    }

    static final Map<Long, Chunk> chunks = new HashMap<>();

    @SuppressWarnings("unchecked")
    static Chunk chunk(int cx, int cz) throws IOException {
        long key = ((long) cx << 32) ^ (cz & 0xffffffffL);
        Chunk cached = chunks.get(key);
        if (cached != null) return cached;
        Chunk c = new Chunk();
        File f = new File(SCRATCH + "region/r." + (cx >> 5) + "." + (cz >> 5) + ".mca");
        if (f.exists()) {
            try (RandomAccessFile raf = new RandomAccessFile(f, "r")) {
                raf.seek(4L * ((cx & 31) + (cz & 31) * 32));
                int loc = raf.readInt();
                int offset = loc >>> 8;
                if (offset != 0) {
                    raf.seek(offset * 4096L);
                    int len = raf.readInt();
                    int comp = raf.readByte();
                    byte[] buf = new byte[len - 1];
                    raf.readFully(buf);
                    InputStream raw = new ByteArrayInputStream(buf);
                    InputStream in = comp == 2 ? new InflaterInputStream(raw) : comp == 1 ? new GZIPInputStream(raw) : raw;
                    DataInputStream din = new DataInputStream(new java.io.BufferedInputStream(in));
                    din.readByte();
                    din.readUTF();
                    Map<String, Object> root = (Map<String, Object>) readTag(din, 10);
                    for (Object so : (List<Object>) root.getOrDefault("sections", List.of())) {
                        Map<String, Object> s = (Map<String, Object>) so;
                        Map<String, Object> bs = (Map<String, Object>) s.get("block_states");
                        if (bs == null) continue;
                        int sy = ((Number) s.get("Y")).intValue();
                        List<Object> pal = (List<Object>) bs.get("palette");
                        String[] names = new String[pal.size()];
                        for (int i = 0; i < names.length; i++) {
                            String n = (String) ((Map<String, Object>) pal.get(i)).get("Name");
                            names[i] = n.substring(n.indexOf(':') + 1).toUpperCase(Locale.ROOT);
                        }
                        c.palettes.put(sy, names);
                        if (bs.get("data") != null) c.data.put(sy, (long[]) bs.get("data"));
                    }
                }
            }
        }
        chunks.put(key, c);
        return c;
    }

    // ---- inputs ------------------------------------------------------------------------------
    record Input(JsonNode json, List<ProfileSet.Profile> profiles, List<MaskBuilder.Seed> seeds,
                 List<NodeMatcher.PreviousNode> nodes, List<NodeMatcher.PreviousEdge> edges,
                 Map<Integer, JsonNode> nodeJson) {
    }

    static Input load(String file) throws IOException {
        JsonNode j = new ObjectMapper().readTree(new File(SCRATCH + "replay/" + file));
        List<ProfileSet.Profile> profiles = new ArrayList<>();
        for (JsonNode p : j.get("profiles")) {
            List<ProposedProfile.Material> mats = new ArrayList<>();
            for (JsonNode m : p.get("materials")) {
                mats.add(new ProposedProfile.Material(m.get("material").asText(), RoadMaterialRole.valueOf(m.get("role").asText().toUpperCase(Locale.ROOT)),
                    m.get("ambiguous").asBoolean(), m.get("centreShare").asDouble(), m.get("edgeShare").asDouble(), m.get("samples").asInt()));
            }
            profiles.add(new ProfileSet.Profile(p.get("id").asInt(), p.get("name").asText(), p.get("enabled").asBoolean(),
                p.get("widthMin").asInt(), p.get("widthMax").asInt(), Set.of(), mats));
        }
        LinkedHashSet<MaskBuilder.Seed> seeds = new LinkedHashSet<>();
        for (JsonNode s : j.get("seeds")) seeds.add(new MaskBuilder.Seed(s.get(0).asInt(), s.get(1).asInt(), s.get(2).asInt()));
        List<NodeMatcher.PreviousNode> nodes = new ArrayList<>();
        Map<Integer, JsonNode> nodeJson = new HashMap<>();
        for (JsonNode n : j.get("nodes")) {
            nodes.add(new NodeMatcher.PreviousNode(n.get("id").asInt(), n.get("x").asInt(), n.get("y").asInt(), n.get("z").asInt(),
                RoadNodeKind.fromApiName(n.get("kind").asText()), n.get("locked").asBoolean()));
            nodeJson.put(n.get("id").asInt(), n);
        }
        List<NodeMatcher.PreviousEdge> edges = new ArrayList<>();
        for (JsonNode e : j.get("edges")) {
            List<int[]> g = new ArrayList<>();
            for (JsonNode p : e.get("geometry")) g.add(new int[] {p.get(0).asInt(), p.get(1).asInt(), p.get(2).asInt()});
            edges.add(new NodeMatcher.PreviousEdge(e.get("id").asInt(), e.get("from").asInt(), e.get("to").asInt(), g));
        }
        return new Input(j, profiles, new ArrayList<>(seeds), nodes, edges, nodeJson);
    }

    static CompactSurfaceGrid grid(Input in, MaskBuilder.Region region) throws IOException {
        Set<String> floor = new HashSet<>();
        for (ProfileSet.Profile p : in.profiles()) {
            if (!p.enabled()) continue;
            p.materials().stream().filter(m -> m.role() != RoadMaterialRole.OVERLAY).forEach(m -> floor.add(m.material().toUpperCase(Locale.ROOT)));
        }
        PassabilityRules rules = PassabilityRules.of(PassabilityRules::curatedCollidable,
            List.of("SNOW", "*_CARPET", "*_PRESSURE_PLATE", "RAIL", "POWERED_RAIL", "LEAF_LITTER", "PINK_PETALS"));
        Predicate<String> roadFloor = floor::contains;
        CompactSurfaceGrid grid = new CompactSurfaceGrid(rules, roadFloor, GateCells.NONE, -64, 320);
        for (int cx = Math.floorDiv(region.minX(), 16); cx <= Math.floorDiv(region.maxX(), 16); cx++) {
            for (int cz = Math.floorDiv(region.minZ(), 16); cz <= Math.floorDiv(region.maxZ(), 16); cz++) {
                Chunk c = chunk(cx, cz);
                grid.capture(c::at, cx, cz);
            }
        }
        return grid;
    }

    static BuildParameters liveParams() {
        return BuildParameters.defaults().withTile(512, 32).withMaxCells(250_000).withGraphRules(5, 15)
            .withAmbiguousReach(2).withPlazaGrowth(4).withLockedNodeReach(8.0).withAutoPlazas(true);
    }

    // ---- variants ----------------------------------------------------------------------------
    record Variant(String label, BuildParameters params, boolean tombstones, boolean locks, boolean anchors,
                   boolean previous, Map<Integer, Integer> plazaOverride) {
    }

    static TileBuildResult run(Input in, Variant v, CompactSurfaceGrid grid) {
        int tx = in.json().get("tileX").asInt();
        int tz = in.json().get("tileZ").asInt();
        List<NodeMatcher.PreviousNode> nodes = new ArrayList<>();
        List<SkeletonGraph.Anchor> anchors = new ArrayList<>();
        List<SkeletonGraph.Plaza> plazas = new ArrayList<>();
        for (NodeMatcher.PreviousNode n : in.nodes()) {
            if (n.kind().isTombstone() && !v.tombstones()) continue;
            nodes.add(v.locks() ? n : new NodeMatcher.PreviousNode(n.id(), n.x(), n.y(), n.z(), n.kind(), n.kind().isTombstone()));
            if (n.kind() == RoadNodeKind.ANCHOR && v.anchors()) anchors.add(new SkeletonGraph.Anchor(n.id(), n.x(), n.y(), n.z()));
            JsonNode j = in.nodeJson().get(n.id());
            Integer radius = j.get("plazaRadius").isNull() ? null : j.get("plazaRadius").asInt();
            if (v.plazaOverride() != null && v.plazaOverride().containsKey(n.id())) radius = v.plazaOverride().get(n.id());
            if (radius != null && radius > 0 && (n.kind() == RoadNodeKind.JUNCTION || n.kind() == RoadNodeKind.ANCHOR)
                && (v.anchors() || n.kind() != RoadNodeKind.ANCHOR)) {
                plazas.add(new SkeletonGraph.Plaza(n.id(), n.x(), n.y(), n.z(), radius));
            }
        }
        NodeMatcher.PreviousGraph prev = v.previous() ? new NodeMatcher.PreviousGraph(nodes, in.edges()) : NodeMatcher.PreviousGraph.EMPTY;
        if (!v.previous()) {
            // tombstones still need to reach the builder through the previous graph
            List<NodeMatcher.PreviousNode> only = nodes.stream().filter(n -> n.kind().isTombstone()).toList();
            prev = new NodeMatcher.PreviousGraph(only, List.of());
        }
        TileBuilder.TileRequest req = new TileBuilder.TileRequest("world_KNK-DEV", tx, tz, v.params(), in.seeds(),
            new ProfileSet(in.profiles()), GateCells.NONE, anchors, prev, plazas);
        return new TileBuilder().build(req, grid);
    }

    static boolean focus(int x, int z) {
        return x >= FOCUS[0] && x <= FOCUS[1] && z >= FOCUS[2] && z <= FOCUS[3];
    }

    static String describe(Input in, TileBuildResult r) {
        StringBuilder sb = new StringBuilder();
        Map<RoadNodeKind, Integer> kinds = new TreeMap<>();
        for (TileBuildResult.Node n : r.nodes()) kinds.merge(n.kind(), 1, Integer::sum);
        sb.append("  nodes ").append(r.nodes().size()).append(' ').append(kinds).append(", edges ").append(r.edges().size())
            .append(", cells ").append(r.cellCount()).append('\n');
        for (String w : r.warningTexts()) sb.append("  warn: ").append(w).append('\n');
        for (TileBuildResult.Correction c : r.corrections()) sb.append(String.format("  corr: %-15s #%-6d %-6s %s at %d,%d,%d%n", c.kind(), c.nodeId(), c.applied() ? "used" : "STALE", c.detail(), c.x(), c.y(), c.z()));
        Map<String, String> label = new HashMap<>();
        for (TileBuildResult.Node n : r.nodes()) {
            String name = n.existingId().isPresent() ? "#" + n.existingId().getAsInt() : n.key();
            JsonNode j = n.existingId().isPresent() ? in.nodeJson().get(n.existingId().getAsInt()) : null;
            if (j != null && !j.get("name").isNull()) name += "(" + j.get("name").asText() + ")";
            label.put(n.key(), name);
            if (focus(n.x(), n.z())) {
                sb.append(String.format("  N %-28s %-9s %d,%d,%d%n", name, n.kind(), n.x(), n.y(), n.z()));
            }
        }
        for (TileBuildResult.Edge e : r.edges()) {
            int[] a = e.geometry().get(0);
            int[] b = e.geometry().get(e.geometry().size() - 1);
            boolean inFocus = false;
            for (int[] p : e.geometry()) inFocus |= focus(p[0], p[2]);
            if (!inFocus) continue;
            StringBuilder g = new StringBuilder();
            for (int[] p : e.geometry()) g.append('[').append(p[0]).append(',').append(p[1]).append(',').append(p[2]).append(']');
            sb.append(String.format("  E %-8s %s -> %s  %.1f m  %s%n", e.existingId().isPresent() ? "#" + e.existingId().getAsInt() : "new",
                label.get(e.fromKey()), label.get(e.toKey()), e.length(), g));
        }
        return sb.toString();
    }

    @Test
    void map() throws IOException {
        String file = System.getProperty("replay.file", "tile_2_-2.json");
        Assumptions.assumeTrue(new File(SCRATCH + "replay/" + file).exists());
        Input in = load(file);
        MaskBuilder.Region region = MaskBuilder.Region.tile(2, -2, 512).grow(32);
        CompactSurfaceGrid grid = grid(in, region);
        Map<String, String> ctl = control();
        String[] box = ctl.getOrDefault("map", "1380,1450,-590,-505,38,56").split(",");
        boolean auto = Boolean.parseBoolean(ctl.getOrDefault("mapauto", "true"));
        BuildParameters params = liveParams().withAutoPlazas(auto);
        net.knightsandkings.knk.core.roads.build.SpanGrid sg = new net.knightsandkings.knk.core.roads.build.SpanGrid(grid, new ProfileSet(in.profiles()), GateCells.NONE);
        MaskBuilder.Result masked = new MaskBuilder(sg, params).build(in.seeds(), region);
        net.knightsandkings.knk.core.roads.build.RoadMask mask = masked.mask();
        int[] dt = net.knightsandkings.knk.core.roads.build.DistanceTransform.compute(mask);
        boolean[] skel = net.knightsandkings.knk.core.roads.build.Thinning.thin(mask);
        int x0 = Integer.parseInt(box[0]), x1 = Integer.parseInt(box[1]), z0 = Integer.parseInt(box[2]), z1 = Integer.parseInt(box[3]), y0 = Integer.parseInt(box[4]), y1 = Integer.parseInt(box[5]);
        StringBuilder sb = new StringBuilder("mask/skeleton y " + y0 + ".." + y1 + "; '#' skeleton, digit = road width (2dt-1, 9+ = '+'), '.' none\n      ");
        for (int x = x0; x <= x1; x++) sb.append(x % 10 == 0 ? (char) ('0' + (x / 10) % 10) : ' ');
        sb.append('\n');
        for (int z = z0; z <= z1; z++) {
            sb.append(String.format("%5d ", z));
            for (int x = x0; x <= x1; x++) {
                char c = '.';
                for (int y = y1; y >= y0; y--) {
                    int i = mask.indexOf(x, y, z);
                    if (i == net.knightsandkings.knk.core.roads.build.RoadMask.NONE) continue;
                    if (skel[i]) { c = '#'; break; }
                    int w = net.knightsandkings.knk.core.roads.build.DistanceTransform.width(dt[i]);
                    c = w > 9 ? '+' : (char) ('0' + w);
                    break;
                }
                sb.append(c);
            }
            sb.append('\n');
        }
        // the graph with a designed Brink plaza of 12: chains lettered
        List<SkeletonGraph.Anchor> anchors = new ArrayList<>();
        List<SkeletonGraph.Pruned> pruned = new ArrayList<>();
        List<SkeletonGraph.Pruned> prunedEdges = new ArrayList<>();
        List<SkeletonGraph.Plaza> plazas = new ArrayList<>();
        for (NodeMatcher.PreviousNode n : in.nodes()) {
            if (n.kind() == RoadNodeKind.ANCHOR) anchors.add(new SkeletonGraph.Anchor(n.id(), n.x(), n.y(), n.z()));
            if (n.kind() == RoadNodeKind.PRUNED) pruned.add(new SkeletonGraph.Pruned(n.id(), n.x(), n.y(), n.z()));
            if (n.kind() == RoadNodeKind.PRUNED_EDGE) prunedEdges.add(new SkeletonGraph.Pruned(n.id(), n.x(), n.y(), n.z()));
        }
        plazas.add(new SkeletonGraph.Plaza(7, 1418, 48, -520, Integer.getInteger("replay.brink", 12)));
        plazas.add(new SkeletonGraph.Plaza(3587, 1390, 42, -576, 12));
        plazas.add(new SkeletonGraph.Plaza(3693, 1441, 42, -563, 12));

        boolean[] skel2 = net.knightsandkings.knk.core.roads.build.Thinning.thin(mask);
        SkeletonGraph.Result g = new SkeletonGraph(mask, skel2, dt, params, new ProfileSet(in.profiles()), MaskBuilder.Region.tile(2, -2, 512))
            .extract(anchors, pruned, prunedEdges, plazas);
        char[][] map = new char[z1 - z0 + 1][x1 - x0 + 1];
        for (char[] row : map) Arrays.fill(row, '.');
        for (int z = z0; z <= z1; z++) for (int x = x0; x <= x1; x++) for (int y = y1; y >= y0; y--) {
            if (mask.indexOf(x, y, z) != net.knightsandkings.knk.core.roads.build.RoadMask.NONE) { map[z - z0][x - x0] = ','; break; }
        }
        StringBuilder legend = new StringBuilder();
        int letter = 0;
        for (SkeletonGraph.Chain ch : g.chains()) {
            boolean shown = false;
            char c = (char) (letter < 26 ? 'a' + letter : 'A' + letter - 26);
            for (int s : ch.spans()) {
                int x = mask.x(s), z = mask.z(s), y = mask.y(s);
                if (x < x0 || x > x1 || z < z0 || z > z1 || y < y0 || y > y1) continue;
                map[z - z0][x - x0] = c;
                shown = true;
            }
            if (shown) {
                SkeletonGraph.Node a = g.nodes().get(ch.from()), b = g.nodes().get(ch.to());
                legend.append(c).append(": ").append(a.kind()).append(a.anchorId().isPresent() ? "#" + a.anchorId().getAsInt() : "").append('@').append(a.x()).append(',').append(a.y()).append(',').append(a.z())
                    .append(" -> ").append(b.kind()).append(b.anchorId().isPresent() ? "#" + b.anchorId().getAsInt() : "").append('@').append(b.x()).append(',').append(b.y()).append(',').append(b.z()).append(" spans ").append(ch.spans().length).append('\n');
                letter++;
            }
        }
        for (SkeletonGraph.Node n : g.nodes()) {
            if (n.x() >= x0 && n.x() <= x1 && n.z() >= z0 && n.z() <= z1 && n.y() >= y0 && n.y() <= y1) map[n.z() - z0][n.x() - x0] = '@';
        }
        sb.append("\nchains (designed plazas, auto off); '@' node, ',' mask\n");
        for (int z = z0; z <= z1; z++) sb.append(String.format("%5d ", z)).append(new String(map[z - z0])).append('\n');
        sb.append(legend);
        java.nio.file.Files.writeString(java.nio.file.Path.of(SCRATCH + "replay/map.txt"), sb.toString(), StandardCharsets.UTF_8);
    }

    static Map<String, String> control() throws IOException {
        Map<String, String> c = new HashMap<>();
        File f = new File(SCRATCH + "replay/control.txt");
        if (f.exists()) for (String line : java.nio.file.Files.readAllLines(f.toPath())) {
            int eq = line.indexOf('=');
            if (eq > 0) c.put(line.substring(0, eq).trim(), line.substring(eq + 1).trim());
        }
        return c;
    }

    @Test
    void replay() throws IOException {
        Assumptions.assumeTrue(!SCRATCH.isEmpty() && new File(SCRATCH + "replay").isDirectory(), "KNK_REPLAY_DIR not set");
        Map<String, String> control = control();
        for (String file : control.getOrDefault("files", "tile_2_-2.json").split(",")) {
            if (new File(SCRATCH + "replay/" + file).exists()) replayTile(file, control.getOrDefault("variants", "live"));
        }
    }

    void replayTile(String file, String which) throws IOException {
        Input in = load(file);
        int tx = in.json().get("tileX").asInt();
        int tz = in.json().get("tileZ").asInt();
        MaskBuilder.Region region = MaskBuilder.Region.tile(tx, tz, 512).grow(32);
        FOCUS = tx == 2 && tz == -2 ? new int[] {1370, 1460, -600, -495} : new int[] {region.minX(), region.maxX(), region.minZ(), region.maxZ()};
        long t0 = System.currentTimeMillis();
        CompactSurfaceGrid grid = grid(in, region);
        StringBuilder out = new StringBuilder("grid captured in " + (System.currentTimeMillis() - t0) + " ms\n");
        BuildParameters live = liveParams();
        Map<String, Variant> variants = new LinkedHashMap<>();
        variants.put("live", new Variant("live (as the server would rebuild now)", live, true, true, true, true, null));
        variants.put("notomb", new Variant("no tombstones (locks, anchors, plazas kept)", live, false, true, true, true, null));
        variants.put("raw", new Variant("raw: no tombstones, locks, anchors, plazas, previous graph", live, false, false, false, false, null));
        variants.put("designed", new Variant("auto-plazas off, Brink plaza 12", live.withAutoPlazas(false), true, true, true, true, Map.of(7, 12)));
        variants.put("c3", new Variant("live, junction-cluster-radius 3", live.withGraphRules(3, 15), true, true, true, true, null));
        variants.put("c1", new Variant("live, junction-cluster-radius 1", live.withGraphRules(1, 15), true, true, true, true, null));
        variants.put("rawc3", new Variant("raw, cluster radius 3", live.withGraphRules(3, 15), false, false, false, false, null));
        for (String key : which.split(",")) {
            Variant v = variants.get(key.trim().replace("-nothin", ""));

            long t = System.currentTimeMillis();
            TileBuildResult r = run(in, v, grid);
            out.append("\n== ").append(key).append(": ").append(v.label()).append(" (").append(System.currentTimeMillis() - t).append(" ms)\n");
            out.append(describe(in, r));
        }
        java.nio.file.Files.writeString(java.nio.file.Path.of(SCRATCH + "replay/out_" + file.replace(".json", "") + ".txt"), out.toString(), StandardCharsets.UTF_8);
    }
}
