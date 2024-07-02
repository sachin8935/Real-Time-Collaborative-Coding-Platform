import "core-js/stable";
import "prosemirror-example-setup/style/style.css";
import "prosemirror-menu/style/menu.css";
import { Plugin, TextSelection } from "prosemirror-state";
import { Decoration, DecorationSet } from "prosemirror-view";
import "prosemirror-view/style/prosemirror.css";
import "regenerator-runtime/runtime";

export const decorateSelections = new Plugin({
  view(view) {
    cable.subscriptions.create(
      {
        channel: "DocumentSelectionChannel",
        document_id: data.id,
      },
      {
        received(selectionData) {
          const tr = view.state.tr;
          tr.setMeta("collab-selection", selectionData);
          view.dispatch(tr);
        },
      }
    );
    return {};
  },
  state: {
    init() {
      return {
        selectionDecorations: {},
        queuedSelections: [],
        decorations: DecorationSet.empty,
      };
    },
    apply(tr, val, _, editorState) {
      val = {
        ...val,
        selectionDecorations: { ...val.selectionDecorations },
        selections: { ...val.selections },
        queuedSelections: [...val.queuedSelections],
      };

      const _selectionData = tr.getMeta("collab-selection");
      if (_selectionData) val.queuedSelections.push(_selectionData);

      if (val.queuedSelections.length > 0) {
        const decorationsToRemove = [];
        const decorationsToAdd = [];

        val.queuedSelections = val.queuedSelections.filter(
          ({ v, head, anchor, client_id }) => {
            const mapping = mappingFromVersion(editorState, v);
            if (!mapping) return true;

            let decorations = val.selectionDecorations[client_id];
            if (decorations) decorationsToRemove.push(...decorations);

            const anchorAssoc = anchor > head ? -1 : 1;
            const headAssoc = anchor * -1;

            const headRes = mapping.mapResult(head, headAssoc);
            const anchorRes = mapping.mapResult(anchor, anchorAssoc);

            if (headRes.deleted || anchorRes.deleted) {
              delete val.selectionDecorations[client_id];
              return;
            }

            const selection = new TextSelection.between(
              editorState.doc.resolve(anchorRes.pos),
              editorState.doc.resolve(headRes.pos)
            );

            const inline = Decoration.inline(selection.from, selection.to, {
              class: "selection",
            });

            decorationsToAdd.push(inline);
            val.selectionDecorations[client_id] = [inline];
          }
        );

        if (decorationsToRemove.length > 0)
          val.decorations = val.decorations.remove(decorationsToRemove);
        if (decorationsToRemove.length > 0)
          val.decorations = val.decorations.add(
            editorState.doc,
            decorationsToAdd
          );
      }

      return val;
    },
  },
  props: {
    decorations(state) {
      return this.getState(state).decorations;
    },
  },
});
