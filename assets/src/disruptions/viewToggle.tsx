import * as React from "react"
import { NavLink, useHistory } from "react-router-dom"
import queryString from "query-string"

enum DisruptionView {
  Draft,
  Published,
}

const useDisruptionViewParam = (): DisruptionView => {
  const { v } = queryString.parse(useHistory().location.search)
  switch (v) {
    case "draft": {
      return DisruptionView.Draft
    }
    default: {
      return DisruptionView.Published
    }
  }
}

const DisruptionViewToggle = () => {
  const view = useDisruptionViewParam()
  return (
    <div className="d-flex flex-column">
      <h5>Select View</h5>
      <NavLink
        id="draft"
        className="btn m-disruption-view-toggle_button"
        to="?v=draft"
        activeClassName="active"
        isActive={() => view === DisruptionView.Draft}
        replace
      >
        create or edit
      </NavLink>
      <NavLink
        id="published"
        className="btn m-disruption-view-toggle_button"
        to="?"
        activeClassName="active"
        isActive={() => view === DisruptionView.Published}
        replace
      >
        published
      </NavLink>
    </div>
  )
}

export { DisruptionViewToggle, DisruptionView, useDisruptionViewParam }
