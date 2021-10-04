import { LitElement, html } from '../web_modules/lit.js';
import '../query.js';
import './wtf.js'

export class Organizer extends LitElement {
    constructor() {
        super();
        this.name = "";
        this.wtfs = [];
    }

    static get properties() {
        return {
            name: { type: String },
            wtfs: { }
        }
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />
        <h2>${this.name}</h2>
        <div class="row">
        ${this.wtfs.map((wtf) => html`
                <wtf-short
                    id=${wtf.id}
                    name=${wtf.name}
                    description=${wtf.description}
                    class="col-6 mb-3">
                </wtf-short>
        `)}
        </div>
        `
    }
}

customElements.define("wtf-organizer", Organizer);