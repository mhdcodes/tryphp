// Support status and install commands. Pure functions, used both when the
// page is built and in the browser (where `today` is the visitor's date, so
// a page built months ago still shows the right status).
import { site, type PhpVersion } from "../config";

export type Tone = "good" | "warn" | "bad";
export type Status = {
  key: "active" | "security" | "eol";
  tone: Tone;
  label: string;
};

// Dates are plain YYYY-MM-DD; parse as local midnight to avoid off-by-one.
function parse(iso: string) {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(y!, m! - 1, d);
}

export function startOfDay(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

const MONTHS = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split(" ");

export function formatDate(iso: string) {
  const d = parse(iso);
  return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

export function status(v: PhpVersion, today: Date): Status {
  if (today <= parse(v.activeUntil))
    return { key: "active", tone: "good", label: "Active support" };
  if (today <= parse(v.securityUntil))
    return { key: "security", tone: "warn", label: "Security fixes only" };
  return { key: "eol", tone: "bad", label: "End of life" };
}

/** "3 years 2 months", "5 months", "under a month"; null once support ended. */
export function timeLeft(v: PhpVersion, today: Date) {
  const end = parse(v.securityUntil);
  if (end < today) return null;
  let months =
    (end.getFullYear() - today.getFullYear()) * 12 +
    (end.getMonth() - today.getMonth());
  if (end.getDate() < today.getDate()) months -= 1;
  if (months < 1) return "under a month";
  const y = Math.floor(months / 12);
  const m = months % 12;
  const parts = [];
  if (y) parts.push(`${y} year${y > 1 ? "s" : ""}`);
  if (m) parts.push(`${m} month${m > 1 ? "s" : ""}`);
  return parts.join(" ");
}

/** The sentence beside the status pill, split so "… left" never wraps. */
export function statusText(v: PhpVersion, today: Date) {
  const left = timeLeft(v, today);
  const until = formatDate(v.securityUntil);
  return left
    ? { main: `Security fixes until ${until} · `, left: `${left} left` }
    : { main: `No fixes since ${until}. For legacy projects only.`, left: "" };
}

export function versionScriptPath(v: PhpVersion) {
  return v.isDefault ? "install.sh" : `${v.id}/install.sh`;
}

export function presetScriptPath(id: string) {
  return `presets/${id}`;
}

export function scriptUrl(path: string) {
  return `${site.url}/${path}`;
}

/** `review` pipes the script into less so it can be read before running. */
export function installCommand(path: string, review = false) {
  return `curl -fsSL ${scriptUrl(path)} | ${review ? "less" : "bash"}`;
}

/**
 * The script URL as HTML that may wrap after each slash past the host, never
 * mid-word. Paths come from config, so they need no escaping.
 */
export function breakableUrl(path: string) {
  return `${site.url}/<wbr>${path.replaceAll("/", "/<wbr>")}`;
}

// Full class names (not built from parts) so Tailwind finds them.
export const dotClass: Record<Tone, string> = {
  good: "bg-good",
  warn: "bg-warn",
  bad: "bg-bad",
};
export const pillClass: Record<Tone, string> = {
  good: "text-good bg-good-soft",
  warn: "text-warn bg-warn-soft",
  bad: "text-bad bg-bad-soft",
};
export const pillBase =
  "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-[9px] py-0.5 text-xs font-medium before:size-1.5 before:rounded-full before:bg-current";
