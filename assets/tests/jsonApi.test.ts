import { toModelObject, parseErrors, toUTCDate } from "../src/jsonApi"
import Adjustment from "../src/models/adjustment"
import DayOfWeek from "../src/models/dayOfWeek"
import DisruptionDiff from "../src/models/disruptionDiff"
import Disruption from "../src/models/disruption"
import Exception from "../src/models/exception"
import TripShortName from "../src/models/tripShortName"

describe("toModelObject", () => {
  test("succeeds with valid adjustment input", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            route_id: "Green-D",
            source: "gtfs_creator",
            source_label: "KenmoreReservoir",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "adjustment",
        },
        included: [],
        jsonapi: { version: "1.0" },
      })
    ).toEqual(
      new Adjustment({
        id: "1",
        routeId: "Green-D",
        source: "gtfs_creator",
        sourceLabel: "KenmoreReservoir",
      })
    )
  })

  test("succeeds with valid day_of_week input", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            start_time: "20:45:00",
            end_time: null,
            day_name: "friday",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "day_of_week",
        },
        included: [],
        jsonapi: { version: "1.0" },
      })
    ).toEqual(
      new DayOfWeek({
        id: "1",
        startTime: "20:45:00",
        dayName: "friday",
      })
    )
  })

  test("succeeds with valid disruption input", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            end_date: "2020-01-12",
            start_date: "2019-12-20",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [{ id: "12", type: "adjustment" }],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "disruption",
        },
        included: [
          {
            attributes: {
              route_id: "Green-D",
              source: "gtfs_creator",
              source_label: "KenmoreReservoir",
            },
            id: "12",
            type: "adjustment",
          },
        ],
        jsonapi: { version: "1.0" },
      })
    ).toEqual(
      new Disruption({
        id: "1",
        startDate: new Date("2019-12-20T00:00:00Z"),
        endDate: new Date("2020-01-12T00:00:00Z"),
        adjustments: [
          new Adjustment({
            id: "12",
            routeId: "Green-D",
            source: "gtfs_creator",
            sourceLabel: "KenmoreReservoir",
          }),
        ],
        daysOfWeek: [],
        exceptions: [],
        tripShortNames: [],
      })
    )
  })

  test("succeeds with valid exception input", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            excluded_date: "2019-12-20",
          },
          id: "1",
          relationships: {
            adjustments: { data: [] },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "exception",
        },
        included: [],
        jsonapi: { version: "1.0" },
      })
    ).toEqual(
      new Exception({
        id: "1",
        excludedDate: new Date("2019-12-20T00:00:00Z"),
      })
    )
  })

  test("succeeds with valid exception input", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            trip_short_name: "1234",
          },
          id: "1",
          relationships: {
            adjustments: { data: [] },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "trip_short_name",
        },
        included: [],
        jsonapi: { version: "1.0" },
      })
    ).toEqual(
      new TripShortName({
        id: "1",
        tripShortName: "1234",
      })
    )
  })

  test("succeeds with valid input containing multiple objects", () => {
    expect(
      toModelObject({
        data: [
          {
            attributes: {
              route_id: "Green-D",
              source: "gtfs_creator",
              source_label: "KenmoreReservoir",
            },
            id: "1",
            relationships: {
              adjustments: {
                data: [],
              },
              days_of_week: { data: [] },
              exceptions: { data: [] },
              trip_short_names: { data: [] },
            },
            type: "adjustment",
          },
          {
            attributes: {
              route_id: "Red",
              source: "gtfs_creator",
              source_label: "HarvardAlewife",
            },
            id: "2",
            relationships: {
              adjustments: {
                data: [],
              },
              days_of_week: { data: [] },
              exceptions: { data: [] },
              trip_short_names: { data: [] },
            },
            type: "adjustment",
          },
        ],
        included: [],
        jsonapi: { version: "1.0" },
      })
    ).toEqual([
      new Adjustment({
        id: "1",
        routeId: "Green-D",
        source: "gtfs_creator",
        sourceLabel: "KenmoreReservoir",
      }),
      new Adjustment({
        id: "2",
        routeId: "Red",
        source: "gtfs_creator",
        sourceLabel: "HarvardAlewife",
      }),
    ])
  })

  test("properly assigns included objects when there are multiple entities", () => {
    expect(
      toModelObject({
        data: [
          {
            attributes: {
              end_date: "2020-01-12",
              start_date: "2019-12-20",
            },
            id: "1",
            relationships: {
              adjustments: {
                data: [{ id: "12", type: "adjustment" }],
              },
              days_of_week: { data: [] },
              exceptions: { data: [] },
              trip_short_names: { data: [] },
            },
            type: "disruption",
          },
          {
            attributes: {
              end_date: "2020-01-15",
              start_date: "2019-12-25",
            },
            id: "2",
            relationships: {
              adjustments: {
                data: [{ id: "13", type: "adjustment" }],
              },
              days_of_week: { data: [] },
              exceptions: { data: [] },
              trip_short_names: { data: [] },
            },
            type: "disruption",
          },
        ],
        included: [
          {
            attributes: {
              route_id: "Green-D",
              source: "gtfs_creator",
              source_label: "KenmoreReservoir",
            },
            id: "12",
            type: "adjustment",
          },
          {
            attributes: {
              route_id: "Green-D",
              source: "gtfs_creator",
              source_label: "Kenmore-Newton",
            },
            id: "13",
            type: "adjustment",
          },
        ],
        jsonapi: { version: "1.0" },
      })
    ).toEqual([
      new Disruption({
        id: "1",
        startDate: new Date("2019-12-20T00:00:00Z"),
        endDate: new Date("2020-01-12T00:00:00Z"),
        adjustments: [
          new Adjustment({
            id: "12",
            routeId: "Green-D",
            source: "gtfs_creator",
            sourceLabel: "KenmoreReservoir",
          }),
        ],
        daysOfWeek: [],
        exceptions: [],
        tripShortNames: [],
      }),
      new Disruption({
        id: "2",
        startDate: new Date("2019-12-25T00:00:00Z"),
        endDate: new Date("2020-01-15T00:00:00Z"),
        adjustments: [
          new Adjustment({
            id: "13",
            routeId: "Green-D",
            source: "gtfs_creator",
            sourceLabel: "Kenmore-Newton",
          }),
        ],
        daysOfWeek: [],
        exceptions: [],
        tripShortNames: [],
      }),
    ])
  })

  test("properly parses nested relationships like with DisruptionDiff", () => {
    expect(
      toModelObject({
        data: [
          {
            attributes: {
              "created?": true,
              diffs: [],
            },
            id: "6",
            relationships: {
              latest_revision: {
                data: {
                  id: "6",
                  type: "disruption",
                },
              },
            },
            type: "disruption_diff",
          },
        ],
        included: [
          {
            attributes: {
              end_date: "2020-09-03",
              start_date: "2020-08-02",
            },
            id: "6",
            relationships: {
              adjustments: {
                data: [
                  {
                    id: "42",
                    type: "adjustment",
                  },
                ],
              },
              days_of_week: {
                data: [
                  {
                    id: "19",
                    type: "day_of_week",
                  },
                  {
                    id: "20",
                    type: "day_of_week",
                  },
                ],
              },
              exceptions: {
                data: [],
              },
              trip_short_names: {
                data: [],
              },
            },
            type: "disruption",
          },

          {
            attributes: {
              day_name: "wednesday",
              end_time: null,
              start_time: null,
            },
            id: "19",
            type: "day_of_week",
          },
          {
            attributes: {
              day_name: "friday",
              end_time: null,
              start_time: null,
            },
            id: "20",
            type: "day_of_week",
          },
          {
            attributes: {
              route_id: "Green-B",
              source: "gtfs_creator",
              source_label: "BostonCollegeWashingtonStreet",
            },
            id: "42",
            type: "adjustment",
          },
        ],
      })
    ).toEqual([
      new DisruptionDiff({
        id: "6",
        disruption: new Disruption({
          id: "6",
          startDate: toUTCDate("2020-08-02"),
          endDate: toUTCDate("2020-09-03"),
          adjustments: [
            new Adjustment({
              id: "42",
              routeId: "Green-B",
              source: "gtfs_creator",
              sourceLabel: "BostonCollegeWashingtonStreet",
            }),
          ],
          daysOfWeek: [
            new DayOfWeek({
              id: "19",
              dayName: "wednesday",
            }),
            new DayOfWeek({
              id: "20",
              dayName: "friday",
            }),
          ],
          exceptions: [],
          tripShortNames: [],
        }),
        isCreated: true,
        diffs: [],
      }),
    ])
  })

  test("returns error when one of multiple objects fails to parse", () => {
    expect(
      toModelObject({
        data: [
          {
            attributes: {
              route_id: "Green-D",
              source: "gtfs_creator",
              source_label: "KenmoreReservoir",
            },
            id: "1",
            relationships: {
              adjustments: {
                data: [],
              },
              days_of_week: { data: [] },
              exceptions: { data: [] },
              trip_short_names: { data: [] },
            },
            type: "adjustment",
          },
          {
            attributes: {
              route_id: "Red",
              source: "gtfs_creator",
              source_label: "HarvardAlewife",
            },
            id: "2",
            relationships: {
              adjustments: {
                data: [],
              },
              days_of_week: { data: [] },
              exceptions: { data: [] },
              trip_short_names: { data: [] },
            },
            type: "not_a_valid_type",
          },
        ],
        included: [],
        jsonapi: { version: "1.0" },
      })
    ).toEqual("error")
  })

  test("return error when included isn't an array", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            route_id: "Green-D",
            source: "gtfs_creator",
            source_label: "KenmoreReservoir",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "adjustment",
        },
        included: "not_an_array",
        jsonapi: { version: "1.0" },
      })
    ).toEqual("error")
  })

  test("returns error when an included object fails to parse", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            end_date: "2020-01-12",
            start_date: "2019-12-20",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [{ id: "12", type: "adjustment" }],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "disruption",
        },
        included: [
          {
            attributes: {
              route_id: "Green-D",
              source: "not_a_valid_source",
              source_label: "KenmoreReservoir",
            },
            id: "12",
            type: "adjustment",
          },
        ],
        jsonapi: { version: "1.0" },
      })
    ).toEqual("error")
  })

  test("returns error when an included object has unknown type", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            end_date: "2020-01-12",
            start_date: "2019-12-20",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [{ id: "12", type: "adjustment" }],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "disruption",
        },
        included: [
          {
            attributes: {
              route_id: "Green-D",
              source: "gtfs_creator",
              source_label: "KenmoreReservoir",
            },
            id: "12",
            type: "not_a_valid_type",
          },
        ],
        jsonapi: { version: "1.0" },
      })
    ).toEqual("error")
  })

  test("returns error when an included value isn't an object", () => {
    expect(
      toModelObject({
        data: {
          attributes: {
            end_date: "2020-01-12",
            start_date: "2019-12-20",
          },
          id: "1",
          relationships: {
            adjustments: {
              data: [{ id: "12", type: "adjustment" }],
            },
            days_of_week: { data: [] },
            exceptions: { data: [] },
            trip_short_names: { data: [] },
          },
          type: "disruption",
        },
        included: ["not_an_object"],
        jsonapi: { version: "1.0" },
      })
    ).toEqual("error")
  })
})

describe("parseErrors", () => {
  test("Parses JSON:API formatted errors into list of errors", () => {
    const data = { errors: [{ detail: "error1" }, { detail: "error2" }] }
    expect(parseErrors(data)).toEqual(["error1", "error2"])
  })

  test("handles oddly shaped data without crashing", () => {
    expect(parseErrors("foo")).toEqual([])
    expect(parseErrors({})).toEqual([])
    expect(parseErrors({ errors: "foo" })).toEqual([])
    expect(parseErrors({ errors: [{ foo: "bar" }] })).toEqual([])
  })
})
