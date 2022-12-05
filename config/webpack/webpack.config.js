// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

const { webpackConfig, config, merge } = require('shakapacker')
const webpack = require('webpack');

const CompressionPlugin = require("compression-webpack-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const WebpackAssetsManifest = require('webpack-assets-manifest');
const { SubresourceIntegrityPlugin } = require("webpack-subresource-integrity");

// Custom ERB loader to disable Spring and prevent crashes
const erb = require("./loaders/erb");

// This setting will change the absolute path used to refer
// external files (images, fonts, ...) in the generated assets
const relative_url_root = process.env.RAILS_RELATIVE_URL_ROOT || '';
const public_output_path = webpackConfig.output.publicPath;

const envConfig = module.exports = {
    node: {
      global: false,
    },
    module: {
        rules: [
            erb
        ]
    },
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin(),
            new CssMinimizerPlugin()
        ],
    },
    output: {
        publicPath: relative_url_root + public_output_path,
        // the following setting is required for SRI to work:
        crossOriginLoading: 'anonymous',
    },
    performance: {
        // Turn off size warnings for large assets
        hints: false
    },
    plugins: [
        new CompressionPlugin(),
        new MiniCssExtractPlugin(),
        new SubresourceIntegrityPlugin(),
        new WebpackAssetsManifest({
            entrypoints: true,
            integrity: true,
            writeToDisk: true,
            entrypointsUseAssets: true,
            publicPath: true,
            output: config.manifestPath,
        })
    ],
    resolve: {
        extensions: ['.css', '.ts', '.tsx'],
        alias: {
            $: 'jquery/src/jquery',
            jquery: 'jquery/src/jquery',
            vis$: 'vis-timeline/standalone',
        }
    },
    stats: 'minimal',
}

// Use the two lines below to remove the original WebpackAssetsManifest and replace it with our custom config.
const filteredPlugins = webpackConfig.plugins.filter((plugin) => !(plugin instanceof WebpackAssetsManifest))
webpackConfig.plugins = filteredPlugins;

module.exports = merge(webpackConfig, envConfig)
