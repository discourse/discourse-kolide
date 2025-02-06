import { i18n } from "discourse-i18n";

function addAssignButton(buffer, matches, state, { parseBBCodeTag }) {
  const parsed = parseBBCodeTag(matches[0], 0, matches[0].length);

  if (!parsed.attrs.user || !parsed.attrs.device) {
    return;
  }

  let token = new state.Token("a_open", "a", 1);
  token.attrs = [
    ["class", "kolide-assign"],
    ["href", "#"],
    ["data-user", parsed.attrs.user],
    ["data-device", parsed.attrs.device],
  ];
  buffer.push(token);

  token = new state.Token("text", "", 0);
  token.content = i18n("discourse_kolide.button.assign");
  buffer.push(token);

  token = new state.Token("a_close", "a", -1);
  buffer.push(token);
}

export function setup(helper) {
  helper.registerOptions((opts, siteSettings) => {
    opts.features["kolide-assign"] = !!siteSettings.kolide_enabled;
  });

  helper.allowList([
    "a.kolide-assign",
    "a[href]",
    "a[data-user]",
    "a[data-device]",
  ]);

  helper.registerPlugin((md) => {
    const rule = {
      matcher: /\[kolide-assign user=.+? device=.+?\]/,
      onMatch: addAssignButton,
    };

    md.core.textPostProcess.ruler.push("kolide-assign", rule);
  });
}
