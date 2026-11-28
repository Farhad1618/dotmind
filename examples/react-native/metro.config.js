const path = require("path");
const { getDefaultConfig } = require("expo/metro-config");

const projectRoot = __dirname;
const libraryRoot = path.resolve(projectRoot, "../../packages/react-native");
const coreRoot = path.resolve(projectRoot, "../../packages/dotmind");
const escape = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

const config = getDefaultConfig(projectRoot);

config.watchFolders = [libraryRoot, coreRoot];
config.resolver.nodeModulesPaths = [path.join(projectRoot, "node_modules")];
config.resolver.blockList = [libraryRoot, coreRoot].map((root) => new RegExp(`^${escape(path.join(root, "node_modules"))}\\/.*$`));

module.exports = config;
