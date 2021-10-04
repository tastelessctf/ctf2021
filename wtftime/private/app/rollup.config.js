
import { nodeResolve } from '@rollup/plugin-node-resolve';

export default [
    {
        input: "node_modules/lit/index.js",
        output: {
            file: "web_modules/lit.js"
        },
        plugins: [nodeResolve()]
    },
    {
        input: "node_modules/lit/directives/unsafe-html.js",
        output: {
            file: "web_modules/unsafe-html.js"
        },
        plugins: [nodeResolve()]
    }
]