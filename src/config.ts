const url = import.meta.env.SITE;

export const site = {
  title: "TryPHP - Effortlessly set up PHP on Linux with a simple curl command",
  description: "Effortlessly set up PHP on Linux with a simple curl command",
  url,
};

export type PhpVersion = {
  id: string;
  /** Last day of bug fixes (ISO date). */
  activeUntil: string;
  /** Last day of security fixes (ISO date). */
  securityUntil: string;
  /** Served at /install.sh; must match PHP_VERSION in src/scripts/php.sh. */
  isDefault?: boolean;
};

// Newest first. Support dates from https://www.php.net/supported-versions.php
export const versions: PhpVersion[] = [
  {
    id: "8.5",
    activeUntil: "2027-12-31",
    securityUntil: "2029-12-31",
    isDefault: true,
  },
  { id: "8.4", activeUntil: "2026-12-31", securityUntil: "2028-12-31" },
  { id: "8.3", activeUntil: "2025-12-31", securityUntil: "2027-12-31" },
  { id: "8.2", activeUntil: "2024-12-31", securityUntil: "2026-12-31" },
  { id: "8.1", activeUntil: "2023-11-25", securityUntil: "2025-12-31" },
  { id: "7.4", activeUntil: "2021-11-28", securityUntil: "2022-11-28" },
];

export const defaultVersion = versions.find((v) => v.isDefault)!;

export type Preset = {
  /** Script name in src/scripts/ and path segment under /presets/. */
  id: string;
  name: string;
  summary: string;
  installs: string[];
};

export const presets: Preset[] = [
  {
    id: "laravel",
    name: "Laravel",
    summary: "PHP 8.5 with the extensions Laravel requires",
    installs: [
      "PHP 8.5 CLI and FPM",
      "The common extensions",
      "Composer",
      "laravel/installer, globally",
    ],
  },
  {
    id: "frankenphp",
    name: "FrankenPHP",
    summary: "FrankenPHP as a systemd service, with a sample site",
    installs: [
      "FrankenPHP binary",
      "A frankenphp system user",
      "systemd service, started on boot",
      "Sample site with phpinfo()",
    ],
  },
];

// Installed with every version by src/scripts/php.sh.
export const extensions = [
  "bcmath",
  "curl",
  "gd",
  "igbinary",
  "imagick",
  "intl",
  "mbstring",
  "memcached",
  "mysql",
  "pcov",
  "pgsql",
  "redis",
  "sqlite3",
  "xdebug",
  "xml",
  "zip",
];
