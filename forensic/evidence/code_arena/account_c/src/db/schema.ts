import { pgTable, serial, text, timestamp } from "drizzle-orm/pg-core";

// Persistence probe: one row is appended on every /api/env-report call.
// If rows (and their timestamps) survive rebuilds/restarts, the database
// layer persists across events; if the table is empty or gone, it does not.
export const arenaMarkers = pgTable("arena_markers", {
  id: serial("id").primaryKey(),
  marker: text("marker").notNull(),
  source: text("source").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true, mode: "string" })
    .notNull()
    .defaultNow(),
});
