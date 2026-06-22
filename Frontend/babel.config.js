module.exports = function(api) {
  api.cache(true);
  return {
    presets: [['babel-preset-expo', { unstable_transformImportMeta: true }]],
    plugins: [
      'babel-plugin-transform-import-meta',
      'react-native-reanimated/plugin'
    ]
  };
};
