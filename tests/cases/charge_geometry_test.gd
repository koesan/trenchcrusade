extends RefCounted

## MechanicsResolver.segment_interposes — hücum çizgisi üzerinde araya giren düşman geometrisi.
## Compendium: hücum düz çizgisinde, hedeften ÖNCE 1" içinden geçilen başka düşman varsa o hedef
## seçilmelidir. Bu saf projeksiyon matematiği (P2-7'de unit.gd'den çıkarıldı) hataya açık; kilitle.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")

func run(t) -> void:
	var a := Vector3(0, 0, 0)
	var b := Vector3(10, 0, 0)
	var r := 1.3

	# Çizginin ortasında, yan mesafe 0.5 (< 1.3) → araya giriyor.
	t.ok(MechanicsResolver.segment_interposes(a, b, Vector3(5, 0, 0.5), r), "Yakın yan nokta araya girer")

	# Çizgi üzerinde tam (yan mesafe 0) → araya giriyor.
	t.ok(MechanicsResolver.segment_interposes(a, b, Vector3(5, 0, 0), r), "Çizgi üstü nokta araya girer")

	# Yan mesafe 2.0 (> 1.3) → araya girmez.
	t.ok(not MechanicsResolver.segment_interposes(a, b, Vector3(5, 0, 2.0), r), "Uzak yan nokta araya girmez")

	# Başlangıçtan geride (proj <= 0) → araya girmez.
	t.ok(not MechanicsResolver.segment_interposes(a, b, Vector3(-1, 0, 0), r), "Saldıranın gerisi araya girmez")

	# Hedefin ötesinde (proj >= |ab|) → araya girmez.
	t.ok(not MechanicsResolver.segment_interposes(a, b, Vector3(11, 0, 0), r), "Hedefin ötesi araya girmez")

	# Dejenere segment (a==b) → araya girmez (sıfıra bölme koruması).
	t.ok(not MechanicsResolver.segment_interposes(a, a, Vector3(0, 0, 0.1), r), "Dejenere segment araya girmez")
