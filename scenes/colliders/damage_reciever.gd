class_name  DamageReciever
extends Area2D

enum HitType {NORMAL, KNOCKDOWN, POWER}

signal damage_recieved(damage: int, direction: Vector2, hit_type : HitType)
