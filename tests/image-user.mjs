// Which non-root user each mcr.microsoft.com/devcontainers image actually
// ships. Setting remoteUser to a name the image does not have makes the
// container fail to start with:
//   unable to find user vscode: no matching entries in passwd file
//
// Verified against the images' devcontainer.metadata label:
//   docker image inspect <image> --format '{{index .Config.Labels "devcontainer.metadata"}}'
export const IMAGE_USER_RULES = [
  [/^mcr\.microsoft\.com\/devcontainers\/(typescript-node|javascript-node)(:|$)/, 'node'],
  [/^mcr\.microsoft\.com\/devcontainers\/universal(:|$)/, 'codespace'],
];

export const DEFAULT_IMAGE_USER = 'vscode';

export function expectedUser(image) {
  return IMAGE_USER_RULES.find(([pattern]) => pattern.test(image))?.[1] ?? DEFAULT_IMAGE_USER;
}

// Strategy B and C fixtures do not carry an "image" field: the image is the
// FROM line of their Dockerfile. Read it so those fixtures get checked too.
export function imageFromDockerfile(text) {
  for (const line of text.split(/\r?\n/)) {
    const match = /^\s*FROM\s+(?:--platform=\S+\s+)?(\S+)/i.exec(line);
    if (match) return match[1].replace(/^\$\{?\w+\}?/, '');
  }
  return '';
}
