import I18n from "I18n";

function addRecheckButton(buffer, matches, state, { parseBBCodeTag }) {
  const parsed = parseBBCodeTag(matches[0], 0, matches[0].length);

  if (!parsed.attrs.issue) {
    return;
  }

  let token = new state.Token("a_open", "a", 1);
  token.attrs = [
    ["class", "kolide-recheck"],
    ["href", "#"],
    ["data-issue", parsed.attrs.issue],
  ];
  buffer.push(token);

  token = new state.Token("text", "", 0);
  token.content = I18n.t("discourse_kolide.button.recheck");
  buffer.push(token);

  token = new state.Token("a_close", "a", -1);
  buffer.push(token);
}

export function setup(helper) {
  helper.registerOptions((opts, siteSettings) => {
    opts.features["kolide-recheck"] = !!siteSettings.kolide_enabled;
  });

  helper.allowList(["a.kolide-recheck", "a[href]", "a[data-issue]"]);

  helper.registerPlugin((md) => {
    const rule = {
      matcher: /\[kolide-recheck issue=.+?\]/,
      onMatch: addRecheckButton,
    };

    md.core.textPostProcess.ruler.push("kolide-recheck", rule);
  });
}
