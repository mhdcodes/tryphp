const url = import.meta.env.SITE;

export const site = {
  title: "TryPHP - Effortlessly set up PHP on Linux with a simple curl command",
  description: "Effortlessly set up PHP on Linux with a simple curl command",
  url,
};

export const mainInstall = `curl -fsSL ${url}/install.sh | bash`;

export const versions = [
  {
    id: "php7.4",
    preset: "PHP7.4",
    code: `curl -fsSL ${url}/7.4/install.sh | bash`,
  },
  {
    id: "php8.1",
    preset: "PHP8.1",
    code: `curl -fsSL ${url}/8.1/install.sh | bash`,
  },
  {
    id: "php8.2",
    preset: "PHP8.2",
    code: `curl -fsSL ${url}/8.2/install.sh | bash`,
  },
  {
    id: "php8.3",
    preset: "PHP8.3",
    code: `curl -fsSL ${url}/8.3/install.sh | bash`,
  },
  {
    id: "php8.4",
    preset: "PHP8.4",
    code: `curl -fsSL ${url}/8.4/install.sh | bash`,
  },
  {
    id: "php8.5",
    preset: "PHP8.5",
    code: `curl -fsSL ${url}/8.5/install.sh | bash`,
  },
];

export const presets = [
  {
    id: "laravel",
    preset: "Laravel",
    code: `curl -fsSL ${url}/presets/laravel | bash`,
  },
  {
    id: "frankenphp",
    preset: "FrankenPHP",
    code: `curl -fsSL ${url}/presets/frankenphp | bash`,
  },
];
