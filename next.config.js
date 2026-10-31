let commitHash = 'no-git-commit';
try {
  commitHash = process.env.COMMIT_SHA || 'no-git-commit';
} catch (error) {
  console.error(`Get git commit hash failed.`);
}

const assetPrefix = process.env.ASSET_PREFIX || '';

module.exports = {
  reactStrictMode: true,
  assetPrefix,
  generateBuildId: async () => {
    return commitHash;
  },
  publicRuntimeConfig: {
    assetPrefix,
  }
}
