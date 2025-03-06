extends Object

const CURRENT_DATA_VERSION = 0

const KNOB_X = 10.0
const KNOB_W = 20.0
const KNOB_H = 5.0
const KNOB_Z = 5.0
const CONTROL_MARGIN = 20.0
const OUTLINE_WIDTH = 3.0
const MINIMUM_SNAP_DISTANCE = 80.0

const FOCUS_BORDER_COLOR = Color(225, 242, 0)

## Properties for builtin categories. Order starts at 10 for the first
## category and then are separated by 10 to allow custom categories to
## be easily placed between builtin categories.
const BUILTIN_CATEGORIES_PROPS: Dictionary = {
	"%siklus_server%":
	{
		"color": Color("ec3b59"),
		"order": 10,
	},
	"%siklus_client%":
	{
		"color": Color("cf6a87"),
		"order": 20,
	},
	"%transformasi_posisi%":
	{
		"color": Color("4b6584"),
		"order": 25,
	},
	"Transform | Rotation":
	{
		"color": Color("4b6584"),
		"order": 30,
	},
	"Transform | Scale":
	{
		"color": Color("4b6584"),
		"order": 40,
	},
	"Graphics | Modulate":
	{
		"color": Color("03aa74"),
		"order": 50,
	},
	"Graphics | Visibility":
	{
		"color": Color("03aa74"),
		"order": 60,
	},
	"Graphics | Viewport":
	{
		"color": Color("03aa74"),
		"order": 61,
	},
	"%animasi%":
	{
		"color": Color("03aa74"),
		"order": 62,
	},
	"%suara%":
	{
		"color": Color("e30fc0"),
		"order": 70,
	},
	"Physics | Mass":
	{
		"color": Color("a5b1c2"),
		"order": 80,
	},
	"Physics | Velocity":
	{
		"color": Color("a5b1c2"),
		"order": 90,
	},
	"%metode%":
	{
		"color": Color("4b7bec"),
		"order": 100,
	},
	"%metode_objek%":
	{
		"color": Color("4b7bec"),
		"order": 110,
	},
	"Info | Score":
	{
		"color": Color("cf6a87"),
		"order": 120,
	},
	"%perulangan%":
	{
		"color": Color("20bf6b"),
		"order": 130,
	},
	"%logika_kondisi%":
	{
		"color": Color("45aaf2"),
		"order": 140,
	},
	"%logika_perbandingan%":
	{
		"color": Color("45aaf2"),
		"order": 150,
	},
	"%logika_boolean%":
	{
		"color": Color("45aaf2"),
		"order": 160,
	},
	"%variabel%":
	{
		"color": Color("ff8f08"),
		"order": 170,
	},
	"%matematika%":
	{
		"color": Color("a55eea"),
		"order": 180,
	},
	"%masukan%":
	{
		"color": Color("d54322"),
		"order": 190,
	},
	"%keluaran%":
	{
		"color": Color("002050"),
		"order": 200,
	},
}
