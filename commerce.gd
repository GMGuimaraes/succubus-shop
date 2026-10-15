extends RefCounted
## Provider-neutral monetization boundary. Product IDs and SDKs are deliberately
## absent until store/legal details are approved; gameplay never shows ads.

const ADS_ENABLED := false
const DLC_CATALOG: Array[Dictionary] = []
const AD_PLACEMENTS := {
	"optional_bonus": {"requires_explicit_click": true, "allowed_during_gameplay": false},
}

static func can_show_ad(placement: String, gameplay_active: bool, user_requested: bool) -> bool:
	if not ADS_ENABLED or not AD_PLACEMENTS.has(placement):
		return false
	var rules: Dictionary = AD_PLACEMENTS[placement]
	if gameplay_active and not bool(rules.get("allowed_during_gameplay", false)):
		return false
	return not bool(rules.get("requires_explicit_click", true)) or user_requested

static func dlc_catalog_is_valid() -> bool:
	var seen_ids: Dictionary = {}
	for product in DLC_CATALOG:
		var product_id := str(product.get("id", "")).strip_edges()
		var app_id := int(product.get("app_id", 0))
		if product_id.is_empty() or app_id <= 0 or seen_ids.has(product_id):
			return false
		seen_ids[product_id] = true
	return true

static func find_dlc(product_id: String) -> Dictionary:
	for product in DLC_CATALOG:
		if str(product.get("id", "")) == product_id:
			return product.duplicate(true)
	return {}
