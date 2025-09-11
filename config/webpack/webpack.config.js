// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.

const { generateWebpackConfig, merge } = require('shakapacker')
const webpackConfig = generateWebpackConfig()

const CompressionPlugin = require("compression-webpack-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");

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
            // Extract Bootstrap's inline SVGs to actual resources.
            // This removes the requirement for `data:` URLs in our CSP
            // See https://getbootstrap.com/docs/5.3/getting-started/webpack/#extracting-svg-files
            {
                mimetype: 'image/svg+xml',
                scheme: 'data',
                type: 'asset/resource',
                generator: {
                    filename: 'icons/[hash].svg'
                },
            },
            // Extract ToastUi's inline PNGs to actual resources, similar to Bootstrap's SVGs.
            // This removes the requirement for `data:` URLs in our CSP
            {
                mimetype: 'image/png',
                scheme: 'data',
                type: 'asset/resource',
                generator: {
                    filename: 'icons/[hash].png'
                },
            }
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
    },
    performance: {
        // Turn off size warnings for large assets
        hints: false
    },
    plugins: [
        new CompressionPlugin(),
        new MiniCssExtractPlugin({
            filename: '[name]-[contenthash].css',
        }),
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

// Enable working source maps in development mode, overwriting the default 'cheap-module-source-map'.
if (webpackConfig.mode === 'development') {
    envConfig.devtool = 'source-map';
}

// Enable source map for SASS / SCSS files, including the original sources in the source map.
webpackConfig.module.rules
  .flatMap(rule => Array.isArray(rule.use) ? rule.use : [])
  .filter(loaderConfig => loaderConfig.options?.sassOptions)
  .forEach(loaderConfig => loaderConfig.options.sassOptions.sourceMapIncludeSources = true);

// Create the resulting config by merging the (modified) default config and our custom setup
module.exports = merge(webpackConfig, envConfig)
