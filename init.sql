CREATE TABLE IF NOT EXISTS chainlink_bridges (
  id SERIAL PRIMARY KEY,
  node_url VARCHAR(255) NOT NULL,
  bridge_name VARCHAR(255) NOT NULL,
  bridge_url VARCHAR(255) NOT NULL
);
