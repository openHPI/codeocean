// Import all the channels to be used by Action Cable
const channels = require.context(".", true, /_channel\.js$/)
channels.keys().forEach(channels)
