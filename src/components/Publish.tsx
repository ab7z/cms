import { User } from "payload/auth"
import { useAuth } from "payload/components/utilities"
import React from "react"
import { toast } from "sonner"

const PublishChanges: React.FC = () => {
  const isDev = process.env.NODE_ENV === "development"

  const auth = useAuth<User>()
  const [preventMultiClick, setPreventMultiClick] = React.useState(false)

  async function clickHandler() {
    if (isDev) return

    setPreventMultiClick(true)

    try {
      toast.promise(commitChanges, {
        loading: "Persisting Changes Requested...",
        success: "Persited",
        error: "Error Persisting Changes. Contact admin.",
      })
    } catch (error) {
      toast.error(`Error Persisting Changes: ${error}`)
    }

    setPreventMultiClick(false)
  }

  async function commitChanges() {
    const headers = new Headers(auth.user ? { userId: auth.user?.id } : {})

    const resp = await fetch(`${window.location.origin}/publish`, {
      method: "GET",
      headers,
    })

    if (parseInt(`${resp.status / 100}`) !== 2) {
      return Promise.reject(new Error("unauthorized"))
    }
  }

  return (
    <>
      {!isDev ? (
        <button
          className='btn--icon-style-without-border'
          style={{
            display: "flex",
            padding: "5px 10px",
          }}
          type='button'
          onClick={clickHandler}
          disabled={preventMultiClick}
        >
          <span
            className='btn__content'
            style={{ color: "var(--theme-text)", margin: 0 }}
          >
            Persist Changes
          </span>
        </button>
      ) : null}
    </>
  )
}

export default PublishChanges
