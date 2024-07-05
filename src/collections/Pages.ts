import type {CollectionConfig} from 'payload/types'
import {HTMLConverterFeature, lexicalEditor, lexicalHTML} from '@payloadcms/richtext-lexical'
import {checkDBConnection, dumpCollection} from "../hooks";

const Pages: CollectionConfig = {
  slug: 'pages',
  access: {
    read: () => true
  },
  hooks: {
    beforeChange: [checkDBConnection],
    afterChange: [dumpCollection]
  },
  fields: [
    {
      name: "identifier",
      label: "FE Identifier",
      type: "text",
      required: true,
    },
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
  ],
}

export default Pages
