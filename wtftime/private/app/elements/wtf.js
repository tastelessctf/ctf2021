import { LitElement, html } from '../web_modules/lit.js';
import { unsafeHTML } from '../web_modules/unsafe-html.js';

class WtfShort extends LitElement {
    constructor() {
        super();
        this.id = 0;
        this.name = "";
        this.description = "";
    }

    static get properties() {
        return {
            id: { type: Number },
            name: { type: String },
            description: { type: String }
        }
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />

        <div class="card">
            <div class="card-body">
                <h5 class="card-title">
                    ${this.id ? html`<a href="#wtf/${this.id}">${this.name}</a>` : this.name}
                </h5>
                <p class="card-text">${unsafeHTML(this.description)}</p>
            </div>
        </div>
        `
    }   
}

customElements.define("wtf-short", WtfShort);