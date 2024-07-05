import type {GlobalConfig} from "payload/types";
import {checkDBConnection, dumpGlobals} from "../hooks";
import {HTMLConverterFeature, lexicalEditor, lexicalHTML} from "@payloadcms/richtext-lexical";

export const Hello: GlobalConfig = {
  slug: "hello",
  access: {
    read: () => true
  },
  hooks: {
    beforeChange: [checkDBConnection],
    afterChange: [dumpGlobals]
  },
  fields: [
    {
      name: 'content',
      type: 'richText',
      editor: lexicalEditor({
        features: ({defaultFeatures}) => [
          ...defaultFeatures,
          HTMLConverterFeature({}),
        ],
      }),
    },
    lexicalHTML('content', {name: 'content_html'}),
  ]
}
