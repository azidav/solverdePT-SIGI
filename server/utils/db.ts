import postgres from "postgres";

// Create a singleton connection (so we don’t reconnect on every request)
const sql = postgres(process.env.DATABASE_URL!, {
  ssl: false, // keep false for local docker
});

export default sql;
