import { useTheme } from "payload/components/utilities"
import React from "react"
import { Toaster } from "sonner"

const CustomToaster: React.FC = () => {
  const { theme } = useTheme()

  return (
    <Toaster
      richColors
      closeButton
      theme={theme}
      invert
    />
  )
}

export default CustomToaster
