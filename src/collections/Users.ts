import type {CollectionConfig} from 'payload/types'
import {checkDBConnection, dumpCollection} from "../hooks";

const Users: CollectionConfig = {
  slug: 'users',
  auth: true,
  admin: {
    useAsTitle: 'email',
  },
  hooks: {
    beforeChange: [checkDBConnection],
    afterChange: [dumpCollection]
  },
  fields: [
    // Email added by default
    // Add more fields as needed
  ],
}

export default Users
