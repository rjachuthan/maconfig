// Pure helper: is herdr's sidebar currently the narrow rail? Mirrors workspace-chrome, which goes by
// the sidebar's width in pixels (dragging its edge narrows it too), not by a flag.
const RAIL_MAX_PX = 160;

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}

export const isNarrow = (tree) => (find(tree, "sidebar")?.size?.px ?? Infinity) < RAIL_MAX_PX;
