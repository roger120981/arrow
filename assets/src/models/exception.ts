import { JsonApiResource, JsonApiResourceData } from "../jsonApiResource"
import JsonApiResourceObject from "../jsonApiResourceObject"
import { ModelObject } from "../jsonApi"

class Exception extends JsonApiResourceObject {
  id?: string
  excludedDate?: Date

  constructor({ id, excludedDate }: { id?: string; excludedDate?: Date }) {
    super()
    this.id = id
    this.excludedDate = excludedDate
  }

  toJsonApi(): JsonApiResource {
    return {
      data: this.toJsonApiData(),
    }
  }

  toJsonApiData(): JsonApiResourceData {
    return {
      type: "exception",
      ...(this.id && { id: this.id.toString() }),
      attributes: {
        ...(this.excludedDate && {
          excluded_date: this.excludedDate.toISOString().slice(0, 10),
        }),
      },
    }
  }

  static fromJsonObject(
    raw: any,
    _included: ModelObject[]
  ): Exception | "error" {
    if (typeof raw.attributes === "object") {
      return new Exception({
        id: raw.id,
        excludedDate: new Date(raw.attributes.excluded_date),
      })
    }

    return "error"
  }
}

export default Exception
