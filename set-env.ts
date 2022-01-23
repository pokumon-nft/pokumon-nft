import * as dotenv from "dotenv";

import path from "path";

export const setEnv = () => {
  const ENV_NAME =
    process.env.NODE_ENV === "production" ? ".env.production" : ".env";
  const ENV_PATH = path.join(__dirname, ENV_NAME);
  dotenv.config({ path: ENV_PATH });
};
