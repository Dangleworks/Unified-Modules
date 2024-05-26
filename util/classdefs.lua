---@diagnostic disable: duplicate-doc-field

---@class Player
---@field steam_id string
---@field peer_id number
---@field name string
---@field is_admin boolean
---@field is_auth boolean
---@field vehicle_limit number?

---@class Vehicle
---@field peer_id number
---@field spawn_coords Coordinates
---@field cost number
---@field loaded boolean
---@field mass number
---@field voxels number
---@field filename string

---@class Coordinates
---@field x number
---@field y number
---@field z number

---@class InternalGroupData
---@field peer_id number
---@field spawn_coords Coordinates
---@field cost number
---@field vehicles Vehicle[]
---@field group_id number
---@field antilag AntilagData?

---@class AntilagData
---@field spawn_time number
---@field spawn_tps number
---@field spawn_tps_avg number
---@field cleared boolean
---@field stabilize_count number