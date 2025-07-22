import type { APIRoute } from "astro";
import { presets } from "../../config";

export function getStaticPaths() {
  return presets.map((p) => ({ params: { preset: p.id } }));
}

export const GET: APIRoute = async ({ params }) => {
  const content = await import(`../../presets/${params.preset}.sh?raw`);
  return new Response(content.default, {
    headers: {
      "Content-Type": "text/plain;charset=UTF-8",
    },
  });
};
