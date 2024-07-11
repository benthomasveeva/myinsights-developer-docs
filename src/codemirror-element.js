import { indentWithTab } from "@codemirror/commands";
import { keymap } from "@codemirror/view";
import { EditorView, basicSetup } from "codemirror";
import { javascript } from "@codemirror/lang-javascript";

export class CustomEditor extends HTMLElement {
  static get observedAttributes() {
    return ["value"];
  }

  editor = null;

  get value() {
    return this.editor?.state.doc.toString() || "";
  }

  set value(newValue) {
    this._setContent(newValue);
  }

  constructor() {
    super();
    this.attachShadow({ mode: "open" });

    const template = document.createElement("div");
    template.id = "editor";
    this.shadowRoot?.appendChild(template);

    const attributes = {};

    for (let i = 0; i < this.attributes.length; i++) {
      if (this.attributes[i].nodeValue) {
        attributes[this.attributes[i].nodeName] = this.attributes[i].nodeValue;
      }
    }

    const thisNode = this;
    function _handleInput(e) {
      if (e.docChanged) {
        thisNode.dispatchEvent(new CustomEvent("codemirrorInput", { detail: e.state.doc.toString() }));
      }
    }

    this.editor = new EditorView({
      ...attributes,
      parent: this.shadowRoot?.getElementById("editor"),
      doc: this.value,
      extensions: [
        basicSetup,
        javascript(),
        keymap.of([indentWithTab]),
        EditorView.lineWrapping,
        EditorView.updateListener.of(_handleInput),
      ],
    });
  }

  _setContent(value) {
    if (value !== this.editor?.state.doc.toString()) {
      this.editor?.dispatch({
        changes: {
          from: 0,
          to: this.editor.state.doc.length,
          insert: value,
        },
      });
    }
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (name === "value") {
      this._setContent(newValue);
    }
  }
}

customElements.define("codemirror-element", CustomEditor); 