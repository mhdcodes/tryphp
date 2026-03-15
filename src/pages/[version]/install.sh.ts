import type { APIRoute } from "astro";

import { versions } from "../../config";

import stub from "../../scripts/php.sh?raw";

export function getStaticPaths() {
  return versions.map((v) => ({
    params: { version: v.id.replace("php", "") },
  }));
}

export const GET: APIRoute = async ({ params }) => {
  const content = stub.replace("8.5", params.version as string);
  return new Response(content, {
    headers: {
      "Content-Type": "text/plain;charset=UTF-8",
    },
  });
};
