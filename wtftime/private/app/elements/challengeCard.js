import { LitElement, html } from '../web_modules/lit.js';
import { unsafeHTML } from '../web_modules/unsafe-html.js';
import '../query.js';

export class ChallengeCard extends LitElement {
    constructor() {
        super();
        this.name = "";
        this.description = "";
        this.points = 0;
    }
    
    static get properties() {
        return {
            name: { type: String },
            points: { type: Number },
            description: { type: String },
        }
    }

    render() {
        return html`
        <link rel="stylesheet" href="/css/bootstrap.min.css" />
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">${this.name} <span class="badge badge-secondary">${this.points}</span></h5>
                <p class="card-text">${unsafeHTML(this.description)}</p>
            </div>
        </div>`
    }
}

customElements.define("challenge-card", ChallengeCard);