from sqlalchemy.orm import Session
import models

INITIAL_PRODUCTS = [
    {
        "nombre": "Portátil Lenovo ThinkPad E14 Gen 5",
        "codigo": "TEC-001",
        "descripcion": "Intel Core i7 13va Gen, 16GB RAM, 512GB SSD NVMe, Pantalla 14 FHD IPS",
        "precio": 3450000.0,
        "cantidad": 12,
        "categoria": "Computadores"
    },
    {
        "nombre": "Monitor Dell UltraSharp 27 4K",
        "codigo": "TEC-002",
        "descripcion": "Resolución 3840x2160, USB-C Hub 90W, sRGB 99%, Panel IPS Antirreflejo",
        "precio": 1680000.0,
        "cantidad": 8,
        "categoria": "Monitores"
    },
    {
        "nombre": "Teclado Mecánico Logitech MX Mechanical",
        "codigo": "ACC-001",
        "descripcion": "Switches Tactile Quiet, Conexión Bluetooth y Logi Bolt, Retroiluminación inteligente",
        "precio": 620000.0,
        "cantidad": 25,
        "categoria": "Accesorios"
    },
    {
        "nombre": "Mouse Ergonómico Logitech MX Master 3S",
        "codigo": "ACC-002",
        "descripcion": "Sensor óptico 8000 DPI, Clics silenciosos, Desplazamiento MagSpeed, Recargable USB-C",
        "precio": 480000.0,
        "cantidad": 30,
        "categoria": "Accesorios"
    },
    {
        "nombre": "Auriculares Inalámbricos Sony WH-1000XM5",
        "codigo": "AUD-001",
        "descripcion": "Cancelación activa de ruido Noise Cancelling, Audio Hi-Res LDAC, 30 horas de batería",
        "precio": 1590000.0,
        "cantidad": 15,
        "categoria": "Audio"
    },
    {
        "nombre": "Disco de Estado Sólido Samsung 990 PRO 2TB",
        "codigo": "ALM-001",
        "descripcion": "M.2 NVMe PCIe 4.0, Velocidad de lectura 7450 MB/s, Ideal para alto rendimiento",
        "precio": 890000.0,
        "cantidad": 20,
        "categoria": "Almacenamiento"
    },
    {
        "nombre": "Memoria RAM Kingston Fury Beast 32GB DDR5",
        "codigo": "ALM-002",
        "descripcion": "Kit 2x16GB a 6000MHz, Perfiles Intel XMP 3.0 y AMD EXPO, Disipador negro",
        "precio": 460000.0,
        "cantidad": 18,
        "categoria": "Componentes"
    },
    {
        "nombre": "Impresora Multifuncional Epson EcoTank L3250",
        "codigo": "OFI-001",
        "descripcion": "Sistema de tanque de tinta continuo, Wi-Fi Direct, Escáner plano y copiado rápido",
        "precio": 850000.0,
        "cantidad": 10,
        "categoria": "Impresión"
    },
    {
        "nombre": "Silla Ergonómica de Oficina Sihoo M57",
        "codigo": "OFI-002",
        "descripcion": "Malla transpirable de alta densidad, Soporte lumbar 3D ajustable, Brazos regulables",
        "precio": 920000.0,
        "cantidad": 7,
        "categoria": "Muebles de Oficina"
    },
    {
        "nombre": "Cámara Web Logitech Brio 4K Ultra HD",
        "codigo": "ACC-003",
        "descripcion": "Video 4K HDR con RightLight 3, Doble micrófono omnidireccional, Enfoque automático",
        "precio": 790000.0,
        "cantidad": 14,
        "categoria": "Accesorios"
    },
    {
        "nombre": "Hub Adaptador USB-C Anker 8 en 1",
        "codigo": "ACC-004",
        "descripcion": "Salida HDMI 4K@60Hz, Carga Power Delivery 100W, Gigabit Ethernet, 2x USB 3.0, Lector SD",
        "precio": 230000.0,
        "cantidad": 40,
        "categoria": "Accesorios"
    },
    {
        "nombre": "Router Wi-Fi 6 TP-Link Archer AX73",
        "codigo": "RED-001",
        "descripcion": "Doble banda Gigabit AX5400, 6 antenas de alta ganancia, Tecnología OneMesh, MU-MIMO",
        "precio": 540000.0,
        "cantidad": 16,
        "categoria": "Redes"
    }
]

def seed_initial_products(db: Session) -> int:
    inserted_count = 0
    for item in INITIAL_PRODUCTS:
        existing = db.query(models.Producto).filter(models.Producto.codigo == item["codigo"]).first()
        if not existing:
            nuevo = models.Producto(
                nombre=item["nombre"],
                codigo=item["codigo"],
                descripcion=item["descripcion"],
                precio=item["precio"],
                cantidad=item["cantidad"],
                categoria=item["categoria"]
            )
            db.add(nuevo)
            inserted_count += 1
    if inserted_count > 0:
        db.commit()
    return inserted_count
