from app.database import SessionLocal, engine, Base
from app.models.models import (
    Usuario, Turista, Administrador,
    SitioArqueologico, Zona, Contenido, CodigoQR
)
from app.auth import hashear_password
import uuid

Base.metadata.create_all(bind=engine)


def poblar_base_de_datos():
    db = SessionLocal()
    try:
        if db.query(Usuario).count() > 0:
            print("La base de datos ya tiene datos.")
            return

        # ============================================================
        # USUARIOS
        # ============================================================
        admin_usuario = Usuario(
            email="admin@quriy.com",
            hashed_password=hashear_password("admin123"),
            rol="admin",
            activo=True
        )
        turista_usuario = Usuario(
            email="turista@quriy.com",
            hashed_password=hashear_password("turista123"),
            rol="turista",
            activo=True
        )
        tourist_usuario = Usuario(
            email="tourist@quriy.com",
            hashed_password=hashear_password("tourist123"),
            rol="turista",
            activo=True
        )
        db.add_all([admin_usuario, turista_usuario, tourist_usuario])
        db.commit()

        admin = Administrador(
            usuario_id=admin_usuario.id,
            nombre="Administrador Quriy",
            institucion="Municipalidad de Cusco"
        )
        db.add(admin)

        turista = Turista(
            usuario_id=turista_usuario.id,
            nombre="Turista Demo",
            idioma_preferido="es"
        )
        tourist = Turista(
            usuario_id=tourist_usuario.id,
            nombre="Tourist Demo",
            idioma_preferido="en"
        )
        db.add_all([turista, tourist])
        db.commit()

        # ============================================================
        # DATA: SITIOS + ZONAS + AUDIOGUIAS
        # ============================================================
        sitios_data = [
            {
                "nombre": "Qorikancha - Templo del Sol",
                "descripcion": (
                    "El Qorikancha, cuyo nombre en quechua significa \"Recinto de Oro\", "
                    "fue el centro religioso mas importante de todo el Imperio Inca y, "
                    "para muchos historiadores, el templo mas sagrado del Tahuantinsuyo. "
                    "Ubicado en pleno corazon del Cusco, sus muros interiores estuvieron "
                    "alguna vez completamente revestidos con laminas de oro puro, capaces "
                    "de reflejar la luz del sol con tal intensidad que, segun cronicas de "
                    "la epoca, deslumbraban a quien se acercaba. Fue construido "
                    "originalmente bajo el nombre de Inticancha por orden del Inca "
                    "Wiracocha, y posteriormente embellecido y ampliado por Pachacutec, "
                    "el gran reformador del imperio. En su interior albergaba recintos "
                    "independientes dedicados al Sol, la Luna, las Estrellas, el Rayo y "
                    "el Arcoiris, funcionando como un verdadero observatorio religioso y "
                    "astronomico. Tras la conquista espanola, gran parte de sus muros "
                    "originales sirvieron de cimiento para la construccion de la Iglesia "
                    "y Convento de Santo Domingo. Hoy en dia recibe alrededor de 1.5 "
                    "millones de visitantes al ano y esta reconocido como Patrimonio "
                    "Cultural de la Humanidad por la UNESCO."
                ),
                "ubicacion": "Av. El Sol, Centro Historico, Cusco",
                "horario": "Lunes a sabado 8:30 - 17:30 / Domingo 14:00 - 17:00",
                "latitud": -13.5183,
                "longitud": -71.9785,
                "zonas": [
                    {
                        "nombre": "Recinto del Sol (Inti)",
                        "descripcion": (
                            "El recinto mas sagrado del Qorikancha, dedicado al dios Sol "
                            "Inti, con paredes que estuvieron revestidas por completo en "
                            "oro puro."
                        ),
                        "audioguia": (
                            "Te encuentras en el corazon espiritual del Imperio Inca: el "
                            "Recinto del Sol. Imagina estas paredes, hoy de piedra desnuda, "
                            "completamente cubiertas de laminas de oro puro, brillando con "
                            "la luz del amanecer andino. Aqui, el cronista Inca Garcilaso "
                            "de la Vega describio una gigantesca figura solar de rostro "
                            "redondo, con rayos y llamas de fuego, forjada en una sola "
                            "pieza de oro macizo. En este mismo espacio, los sacerdotes "
                            "mantenian encendida dia y noche una llama sagrada que jamas "
                            "debia apagarse, y celebraban aqui las ceremonias mas "
                            "importantes del calendario religioso inca, incluido el gran "
                            "Inti Raymi, la Fiesta del Sol. Todo el oro fue saqueado "
                            "durante la conquista espanola, pero la precision de la piedra "
                            "que ves frente a ti sigue siendo testimonio del nivel de "
                            "dominio tecnico y espiritual que alcanzo esta civilizacion. "
                            "Fijate en las hornacinas trapezoidales que aun se conservan "
                            "en los muros: se cree que servian tanto para sostener objetos "
                            "ceremoniales como para generar efectos de luz y sombra "
                            "durante los rituales."
                        ),
                    },
                    {
                        "nombre": "Templo de la Luna (Mama Killa)",
                        "descripcion": (
                            "Recinto dedicado a Mama Killa, la Luna, con paredes "
                            "revestidas en plata y nichos donde se guardaban ofrendas "
                            "sagradas."
                        ),
                        "audioguia": (
                            "Estas en el Templo de la Luna, dedicado a Mama Killa, "
                            "considerada esposa del Sol y protectora de las mujeres en la "
                            "cosmovision inca. A diferencia del recinto vecino, aqui las "
                            "paredes no se cubrian de oro sino de plata, un metal que los "
                            "incas asociaban directamente con el brillo lunar. En este "
                            "espacio se guardaban las momias de las Qollas, las esposas "
                            "principales de los Incas, tratadas con el maximo respeto y "
                            "reverencia religiosa. Observa los nueve nichos trapezoidales "
                            "tallados en la pared del fondo, y las cinco hornacinas "
                            "simetricas en cada muro lateral: se cree que ahi se colocaban "
                            "ofrendas o pequenos idolos ceremoniales. Este es, junto al "
                            "Recinto del Sol, uno de los ambientes mejor conservados de "
                            "todo el Qorikancha, y te permite apreciar de cerca la "
                            "extraordinaria precision de la canteria inca, ensamblada sin "
                            "usar ningun tipo de mortero."
                        ),
                    },
                    {
                        "nombre": "Templo de Venus y las Estrellas",
                        "descripcion": (
                            "Pequeno recinto dedicado a Venus y las Pleyades, clave para "
                            "el calendario agricola y el culto astronomico inca."
                        ),
                        "audioguia": (
                            "Este pequeno pero significativo espacio estuvo dedicado a "
                            "Venus, a la que los incas llamaban Chasca, y a las Pleyades, "
                            "conocidas como las Siete Cabrillas. Para los astronomos "
                            "incas, observar estos cuerpos celestes no era un simple "
                            "ejercicio contemplativo: de su posicion dependian decisiones "
                            "agricolas cruciales, como el momento exacto para sembrar o "
                            "cosechar. Las paredes de este templo, igual que las del "
                            "Templo de la Luna con el que colinda, estuvieron forradas con "
                            "planchas de plata pulida. Un dato fascinante es que, durante "
                            "el solsticio de invierno, este recinto recibia una "
                            "iluminacion especial que los sacerdotes interpretaban como un "
                            "mensaje directo del cosmos. Estas, en definitiva, frente a "
                            "uno de los espacios mas vinculados a la astronomia sagrada de "
                            "todo el complejo del Qorikancha."
                        ),
                    },
                    {
                        "nombre": "Templo del Rayo (Illapa)",
                        "descripcion": (
                            "Templo dedicado a Illapa, dios del rayo y el trueno, "
                            "vinculado a las lluvias y la fertilidad de la tierra."
                        ),
                        "audioguia": (
                            "Te encuentras en el Templo del Rayo, dedicado a Illapa, "
                            "tambien llamado Chuki Illapa, la deidad que representaba el "
                            "relampago, el trueno y el rayo. Para los incas, estos "
                            "fenomenos eran a la vez temidos y venerados, ya que estaban "
                            "directamente relacionados con las lluvias que hacian posible "
                            "la agricultura en los Andes. Observa las tres puertas de "
                            "dintel simple que ves frente a ti, dispuestas de forma "
                            "equidistante y ligeramente trapezoidal, junto con una ventana "
                            "tallada en cada muro lateral que permitia el paso controlado "
                            "de luz natural. En este mismo lugar, los sacerdotes acudian "
                            "durante las tormentas para hacer ofrendas y pedir lluvias "
                            "favorables para las cosechas. Illapa era, ademas, una de las "
                            "tres divinidades mas poderosas del panteon inca junto al Sol "
                            "y Viracocha."
                        ),
                    },
                    {
                        "nombre": "Templo del Arcoiris (K'uychi)",
                        "descripcion": (
                            "Templo dedicado a K'uychi, el Arcoiris, considerado puente "
                            "sagrado entre el cielo y la tierra."
                        ),
                        "audioguia": (
                            "Este es el Templo del Arcoiris, dedicado a K'uychi, al que "
                            "los incas consideraban una emanacion directa del Sol y un "
                            "puente sagrado que unia el mundo celestial con el mundo "
                            "terrenal. Fijate en la arquitectura: comparte las mismas "
                            "proporciones y puertas trapezoidales que el vecino Templo de "
                            "Illapa, lo que sugiere que ambos espacios formaban parte de "
                            "un mismo conjunto dedicado a los fenomenos del cielo. Segun "
                            "las cronicas coloniales, estas paredes llegaron a tener "
                            "pintado un arcoiris en colores vibrantes, convirtiendo este "
                            "recinto en un simbolo visual muy poderoso de conexion entre "
                            "ambos mundos. Es interesante notar que, en la bandera actual "
                            "del Cusco, el arcoiris sigue siendo un simbolo central, una "
                            "herencia directa de esta veneracion inca."
                        ),
                    },
                    {
                        "nombre": "Intipampa (Patio Central)",
                        "descripcion": (
                            "Patio central del Qorikancha y punto de origen del sistema "
                            "de ceques hacia todo el Imperio Inca."
                        ),
                        "audioguia": (
                            "Estas parado en el Intipampa, el Campo del Sol, el patio "
                            "central que articulaba todo el complejo religioso del "
                            "Qorikancha. Bajo tus pies existieron alguna vez cinco "
                            "fuentes ceremoniales de agua, cuyo origen exacto era un "
                            "secreto celosamente guardado por los sacerdotes del templo. "
                            "Desde este mismo patio se accedia a todos los recintos "
                            "sagrados que rodean el Qorikancha. Pero su importancia va "
                            "mucho mas alla de lo arquitectonico: este patio fue el punto "
                            "de origen del sistema de ceques, 41 lineas imaginarias que se "
                            "proyectaban desde aqui hacia 328 lugares sagrados o huacas, "
                            "repartidos por todo el territorio del Tahuantinsuyo. Estas "
                            "parado en el centro simbolico y espiritual de todo el "
                            "Imperio Inca."
                        ),
                    },
                ],
            },
            {
                "nombre": "Plaza de Armas del Cusco",
                "descripcion": (
                    "La Plaza de Armas de Cusco, conocida en tiempos del Tahuantinsuyo "
                    "como Huacaypata o Aucaypata, es el corazon historico, politico y "
                    "simbolico de la ciudad desde hace mas de 500 anos. Durante el "
                    "incanato era un espacio ceremonial de enorme importancia donde se "
                    "realizaban festividades religiosas, desfiles militares y actos "
                    "politicos de primer nivel. La plaza original era considerablemente "
                    "mas grande que la actual y estaba dividida por un canal de agua que "
                    "traia el caudal del rio Saphy directamente al centro ceremonial. Con "
                    "la llegada de los espanoles, la plaza se transformo radicalmente en "
                    "el escenario principal del nuevo poder colonial, rodeandose de "
                    "imponentes construcciones religiosas como la Catedral y la Iglesia "
                    "de la Compania de Jesus. Fue declarada Patrimonio Cultural de la "
                    "Humanidad por la UNESCO en 1983, y hoy sigue siendo el epicentro "
                    "absoluto de la vida cusquena."
                ),
                "ubicacion": "Centro Historico, Cusco",
                "horario": "Acceso libre las 24 horas",
                "latitud": -13.5170,
                "longitud": -71.9787,
                "zonas": [
                    {
                        "nombre": "Catedral del Cusco",
                        "descripcion": (
                            "El templo mas importante de Cusco, construido sobre el "
                            "antiguo palacio del Inca Viracocha."
                        ),
                        "audioguia": (
                            "Frente a ti se alza la Catedral del Cusco, el templo mas "
                            "importante de la ciudad y una de las maximas expresiones del "
                            "arte religioso colonial en toda Sudamerica. Fue construida "
                            "sobre los cimientos del palacio del Inca Viracocha, "
                            "reutilizando piedras cuidadosamente talladas que provenian "
                            "de la fortaleza de Sacsayhuaman, y su edificacion tomo casi "
                            "100 anos en completarse. En su interior encontraras una "
                            "vasta coleccion de obras de la Escuela Cusquena de pintura, "
                            "retablos banados en pan de oro y piezas de orfebreria "
                            "colonial de gran valor historico. Busca, si entras, la "
                            "famosa pintura de la Ultima Cena, donde Jesus y sus "
                            "apostoles comparten en la mesa cuy, comida tipica andina. "
                            "Otro dato curioso: la campana mas grande de la Catedral, "
                            "conocida como \"Maria Angola\", puede escucharse a varios "
                            "kilometros de distancia cuando repica."
                        ),
                    },
                    {
                        "nombre": "Iglesia de la Compania de Jesus",
                        "descripcion": (
                            "Iglesia barroca construida sobre el palacio del Inca Huayna "
                            "Capac, famosa por su fachada de piedra tallada."
                        ),
                        "audioguia": (
                            "Esta es la Iglesia de la Compania de Jesus, construida por "
                            "la orden jesuita sobre lo que fue el palacio del Inca Huayna "
                            "Capac. Esta considerada una de las expresiones mas hermosas "
                            "del arte barroco colonial en toda America del Sur. Observa "
                            "con atencion su fachada: columnas salomonicas, detalles "
                            "ornamentales tallados directamente en piedra y una "
                            "composicion que durante siglos compitio en belleza con la "
                            "Catedral, ubicada justo enfrente, en la misma plaza. Cuenta "
                            "la tradicion que su construccion genero una fuerte disputa "
                            "con el Obispado del Cusco, que temia que esta iglesia "
                            "terminara opacando en grandeza a la propia Catedral, un "
                            "conflicto que llego incluso a oidos del Rey de Espana."
                        ),
                    },
                    {
                        "nombre": "Atrio y Pileta Central",
                        "descripcion": (
                            "Espacio central de la plaza, escenario historico de grandes "
                            "ceremonias incas y de la ejecucion de Tupac Amaru II."
                        ),
                        "audioguia": (
                            "Te encuentras en el corazon mismo de la Plaza de Armas, "
                            "junto a la pileta colonial que se ha convertido en punto de "
                            "encuentro de toda la ciudad. Durante el Incanato, este mismo "
                            "espacio albergaba las grandes ceremonias publicas del "
                            "imperio, incluyendo el Inti Raymi, la Fiesta del Sol. Pero "
                            "este lugar guarda tambien una memoria historica mas dura y "
                            "dramatica: aqui fue ejecutado en 1781 Tupac Amaru II, lider "
                            "de la mayor rebelion indigena contra el dominio colonial "
                            "espanol, un episodio que marco profundamente la historia de "
                            "la region y que sigue siendo recordado como un simbolo de "
                            "resistencia."
                        ),
                    },
                    {
                        "nombre": "Portales y Arcos Coloniales",
                        "descripcion": (
                            "Galerias de arcos coloniales que rodean la plaza, con "
                            "restaurantes, tiendas y balcones de madera tallada."
                        ),
                        "audioguia": (
                            "A tu alrededor puedes ver los portales que enmarcan toda la "
                            "Plaza de Armas: galerias de arcos de piedra construidos "
                            "durante la epoca colonial que hoy albergan restaurantes, "
                            "tiendas de artesania y cafes con balcones de madera tallada "
                            "que miran directamente hacia la plaza. Estos balcones son, "
                            "de hecho, uno de los mejores lugares para observar los "
                            "grandes eventos culturales que se celebran en Cusco a lo "
                            "largo del ano, como el Inti Raymi, el Corpus Christi o las "
                            "Fiestas Patronales. Cada portal tiene un nombre propio "
                            "heredado de la epoca colonial, como el Portal de Panes o el "
                            "Portal de Carnes, referencias directas a los gremios y "
                            "comercios que se instalaban tradicionalmente bajo cada "
                            "tramo de arcos."
                        ),
                    },
                    {
                        "nombre": "Plazoleta Regocijo",
                        "descripcion": (
                            "La \"segunda plaza\" del Cusco, antigua Cusipata inca, hoy "
                            "sede de la Municipalidad."
                        ),
                        "audioguia": (
                            "Estas en la Plazoleta Regocijo, conocida popularmente como "
                            "la \"segunda plaza\" del Cusco. En epoca incaica este espacio "
                            "se llamaba Cusipata y formaba parte del mismo gran conjunto "
                            "ceremonial que hoy conocemos como el centro historico de la "
                            "ciudad. Con el paso de los siglos se convirtio en un espacio "
                            "mas intimo y tranquilo que su vecina, la Plaza de Armas. Hoy "
                            "alberga la sede de la Municipalidad del Cusco y varios "
                            "establecimientos culturales. Su nombre actual, Regocijo, "
                            "proviene de las celebraciones y festejos coloniales que se "
                            "organizaban aqui."
                        ),
                    },
                ],
            },
            {
                "nombre": "Piedra de los 12 Angulos",
                "descripcion": (
                    "La Piedra de los 12 Angulos es una de las atracciones "
                    "arqueologicas mas iconicas y fotografiadas del Cusco, ubicada en "
                    "la calle Hatun Rumiyoc, a apenas 150 metros de la Plaza de Armas. "
                    "Este enorme bloque de piedra, hecho de diorita, forma parte de los "
                    "muros del antiguo Palacio del Inca Roca y destaca por sus 12 caras "
                    "perfectamente talladas que encajan con las piedras adyacentes sin "
                    "utilizar ningun tipo de mortero. Las juntas son tan exactas que, "
                    "segun la tradicion popular, no cabe ni una hoja de papel entre "
                    "ellas. El monumento ha sobrevivido practicamente intacto a varios "
                    "terremotos importantes que sacudieron la region en 1650, 1749 y "
                    "1950. Esta considerada Patrimonio Cultural de la Nacion del Peru."
                ),
                "ubicacion": "Calle Hatun Rumiyoc, Barrio de San Blas, Cusco",
                "horario": "Acceso libre las 24 horas (guardias de 7am a 7pm)",
                "latitud": -13.5160,
                "longitud": -71.9775,
                "zonas": [
                    {
                        "nombre": "La Piedra Principal",
                        "descripcion": (
                            "El bloque de piedra con sus famosos 12 angulos, simbolo "
                            "del ingenio arquitectonico inca."
                        ),
                        "audioguia": (
                            "Tienes frente a ti la Piedra de los 12 Angulos, uno de los "
                            "simbolos mas reconocidos de la ingenieria inca. Este "
                            "bloque, tallado en diorita, mide aproximadamente 1.6 metros "
                            "de alto y se estima que pesa entre 6 y 8 toneladas. Fue "
                            "labrado durante la expansion urbana del Cusco incaico, "
                            "cuando el Inca Roca ordeno construir su palacio en este "
                            "mismo sector de la ciudad. Observa con atencion sus doce "
                            "caras: encajan con las piedras vecinas con tanta precision "
                            "que, segun la tradicion popular, no cabe ni una hoja de "
                            "papel entre ellas. Los arquitectos incas lograban esta "
                            "resistencia sismica gracias a un sistema de piedras "
                            "trapezoidales que se inclinan levemente hacia adentro, "
                            "permitiendo que todo el muro absorba y disipe el "
                            "movimiento telurico."
                        ),
                    },
                    {
                        "nombre": "Muro Inca de Hatun Rumiyoc",
                        "descripcion": (
                            "El extenso muro del antiguo Palacio del Inca Roca, con "
                            "piedras poligonales ensambladas sin mortero."
                        ),
                        "audioguia": (
                            "Este es el extenso muro inca en el que se inserta la "
                            "famosa piedra de los doce angulos, perteneciente al "
                            "antiguo Palacio del Inca Roca. La calle donde te "
                            "encuentras, Hatun Rumiyoc, significa en quechua \"calle de "
                            "las piedras grandes\", y es en si misma un monumento vivo: "
                            "fijate como los muros a ambos lados exhiben la "
                            "extraordinaria tecnica constructiva inca de piedras "
                            "poligonales de distintos tamanos, todas ensambladas sin "
                            "utilizar ningun tipo de mortero. Algunos investigadores han "
                            "contado mas de 30 caras distintas solo en este tramo de "
                            "muro, cada una tallada de forma individual para encajar "
                            "perfectamente con sus vecinas."
                        ),
                    },
                    {
                        "nombre": "Palacio Arzobispal y Museo de Arte Religioso",
                        "descripcion": (
                            "Edificio colonial construido sobre el Palacio del Inca "
                            "Roca, hoy Museo de Arte Religioso del Cusco."
                        ),
                        "audioguia": (
                            "Frente a ti se encuentra el antiguo Palacio Arzobispal, "
                            "construido durante la epoca colonial directamente sobre "
                            "los cimientos del Palacio del Inca Roca. Hoy alberga el "
                            "Museo de Arte Religioso del Cusco, un espacio donde la "
                            "fusion entre los solidos muros incas que sostienen la "
                            "planta baja y la arquitectura colonial de los pisos "
                            "superiores se convierte en uno de los ejemplos mas claros "
                            "del sincretismo arquitectonico que caracteriza a toda la "
                            "ciudad. El costo de entrada aproximado es de S/15, "
                            "alrededor de 4 dolares americanos. Uno de los detalles mas "
                            "llamativos del interior es la coleccion de lienzos de la "
                            "Escuela Cusquena que decoran distintas salas."
                        ),
                    },
                    {
                        "nombre": "Calle Hatun Rumiyoc (Recorrido)",
                        "descripcion": (
                            "Calle empedrada que conecta la Plaza de Armas con la "
                            "Piedra de los 12 Angulos, flanqueada por muros incas."
                        ),
                        "audioguia": (
                            "Estas recorriendo la calle Hatun Rumiyoc, la via empedrada "
                            "que conecta la Plaza de Armas con la Piedra de los 12 "
                            "Angulos. Este camino es, en si mismo, parte fundamental de "
                            "la experiencia turistica: es peatonal, de facil acceso, y "
                            "esta flanqueado a ambos lados por muros incas "
                            "perfectamente conservados, tiendas de artesanos locales y "
                            "vendedores de textiles tradicionales. Es muy probable que a "
                            "lo largo de tu recorrido te encuentres con el reconocido "
                            "\"Inca\" que custodia la piedra, un personaje local vestido "
                            "con atuendo tradicional que se ha convertido en parte del "
                            "paisaje humano de la zona."
                        ),
                    },
                ],
            },
            {
                "nombre": "Qenqo",
                "descripcion": (
                    "Qenqo, cuya traduccion del quechua Q'inqu significa \"laberinto\" o "
                    "\"zigzag\", es uno de los sitios arqueologicos mas enigmaticos y "
                    "menos comprendidos de todo el Cusco. Ubicado a 4 kilometros al "
                    "noreste del centro historico, a 3,580 metros sobre el nivel del "
                    "mar, funciono como un importante centro ceremonial inca donde se "
                    "realizaban rituales relacionados con la adoracion a la Pachamama y "
                    "a otras deidades del panteon andino. Lo mas sorprendente de Qenqo "
                    "es que esta esculpido casi por completo sobre un gigantesco "
                    "afloramiento rocoso natural, en lugar de estar construido con "
                    "piedras trasladadas. El complejo incluye galerias subterraneas, "
                    "canales tallados en zigzag, un anfiteatro semicircular y varias "
                    "camaras ceremoniales de caracter ritual. Qenqo esta incluido "
                    "dentro del Boleto Turistico General del Cusco."
                ),
                "ubicacion": "Cerro Socorro, a 4 km del Centro Historico, Cusco",
                "horario": "7:00 AM - 6:00 PM",
                "latitud": -13.5082,
                "longitud": -71.9648,
                "zonas": [
                    {
                        "nombre": "Anfiteatro Semicircular",
                        "descripcion": (
                            "Espacio ceremonial semicircular con un gran monolito "
                            "central y acustica excepcional."
                        ),
                        "audioguia": (
                            "Te encuentras en el gran Anfiteatro Semicircular de Qenqo, "
                            "una enorme area de 55 metros de largo con 19 hornacinas "
                            "distribuidas a lo largo de su muro curvo. Durante el "
                            "incanato, este espacio funciono como un templo para "
                            "ceremonias publicas. Observa el centro del anfiteatro: ahi "
                            "se levanta un monolito de aproximadamente 6 metros de "
                            "altura sobre un pedestal rectangular, que pudo representar "
                            "a una deidad o a la Pachamama, la Madre Tierra. La forma "
                            "semicircular de este espacio no es casual: le otorga una "
                            "acustica excepcional, ideal para ceremonias con grandes "
                            "congregaciones de fieles. Si hablas en voz baja de pie "
                            "junto al muro curvo, notaras que tu voz se proyecta con "
                            "una claridad sorprendente hacia el centro del anfiteatro."
                        ),
                    },
                    {
                        "nombre": "Canales en Zigzag",
                        "descripcion": (
                            "Canales tallados en la roca que simbolizan a la serpiente "
                            "sagrada, usados en rituales de libacion."
                        ),
                        "audioguia": (
                            "Frente a ti estan los enigmaticos canales de Qenqo, "
                            "tallados directamente en la roca viva y dispuestos en un "
                            "patron de zigzag. Habrian sido utilizados para rituales de "
                            "libacion durante las ceremonias religiosas del sitio. Este "
                            "diseno en zigzag no es decorativo: simboliza el movimiento "
                            "de la serpiente, un animal considerado sagrado en la "
                            "cosmovision andina y asociado al inframundo. Algunos "
                            "investigadores sostienen que estos canales conducian "
                            "chicha, la bebida ceremonial andina, mientras que otros "
                            "plantean una hipotesis mas inquietante: que pudieron "
                            "transportar sangre de sacrificios rituales durante "
                            "festividades especificas del calendario religioso inca."
                        ),
                    },
                    {
                        "nombre": "Camara Subterranea (Altar de Sacrificios)",
                        "descripcion": (
                            "Espacio subterraneo tallado en roca, asociado a "
                            "momificaciones y sacrificios rituales."
                        ),
                        "audioguia": (
                            "Estas a punto de ingresar a uno de los espacios mas "
                            "sagrados y misteriosos de todo Qenqo: la camara "
                            "subterranea, tallada directamente en la roca. Diversas "
                            "investigaciones arqueologicas sugieren que este espacio "
                            "fue utilizado para procesos de momificacion y posibles "
                            "sacrificios rituales, tanto de animales como, segun "
                            "algunas teorias, de personas, en contextos ceremoniales de "
                            "gran relevancia religiosa. En su interior se han "
                            "encontrado restos de cenizas, lo que refuerza la hipotesis "
                            "de que aqui se practicaban cultos a los antepasados. "
                            "Muchos guias locales cuentan que, al entrar aqui, se "
                            "percibe un descenso notable de temperatura."
                        ),
                    },
                    {
                        "nombre": "Tallas y Simbolos en Roca",
                        "descripcion": (
                            "Figuras talladas de condor, puma y serpiente que "
                            "representan la triada sagrada andina."
                        ),
                        "audioguia": (
                            "En las superficies rocosas que te rodean puedes observar "
                            "numerosas figuras talladas que representan a los animales "
                            "sagrados de la cosmovision andina. Busca al condor, "
                            "asociado al mundo celestial o Hanan Pacha; al puma, "
                            "vinculado al mundo terrenal o Kay Pacha; y a la serpiente, "
                            "relacionada con el inframundo o Uku Pacha. Juntas, estas "
                            "tres figuras conforman la base de la triada sagrada "
                            "andina. Esta misma triada sigue siendo hoy un simbolo muy "
                            "utilizado en el arte y la identidad cultural andina "
                            "contemporanea."
                        ),
                    },
                    {
                        "nombre": "Monolito Central",
                        "descripcion": (
                            "Gran bloque de piedra en el centro del anfiteatro, "
                            "posiblemente una deidad con rasgos de felino."
                        ),
                        "audioguia": (
                            "Frente a ti se encuentra el gran Monolito Central de "
                            "Qenqo, ubicado en el corazon del anfiteatro semicircular, "
                            "con aproximadamente 6 metros de altura. Aunque el paso del "
                            "tiempo y los intentos de destruccion durante la epoca "
                            "colonial desgastaron parte de sus formas originales, "
                            "distintos investigadores creen que representaba a una "
                            "deidad con rasgos de felino. Durante el solsticio de "
                            "invierno, la luz solar penetra en angulos muy especificos "
                            "que iluminan directamente este monolito, lo que sugiere un "
                            "uso astronomico deliberado en su ubicacion y orientacion "
                            "original."
                        ),
                    },
                ],
            },
            {
                "nombre": "Cristo Blanco",
                "descripcion": (
                    "El Cristo Blanco es un monumento iconico de 8 metros de altura "
                    "ubicado en la cima del cerro Pukamoqo (Cerro Rojo), a 3,575 "
                    "metros sobre el nivel del mar y aproximadamente 5 kilometros del "
                    "centro historico del Cusco. Fue inaugurado en 1945 como un regalo "
                    "de la colonia arabe-palestina residente en la ciudad, en senal de "
                    "profunda gratitud por la acogida que recibieron. Fue elaborado por "
                    "el artesano local Ernesto Olazo Olivera utilizando granito "
                    "revestido en marmol y yeso. Desde 1972 forma parte de la Zona "
                    "Monumental del Cusco, declarada Monumento Historico del Peru, y "
                    "desde 1983 integra el conjunto declarado Patrimonio Cultural de la "
                    "Humanidad por la UNESCO. Es considerado el mejor mirador "
                    "panoramico de toda la ciudad de Cusco."
                ),
                "ubicacion": "Cerro Pukamoqo, cerca de Sacsayhuaman, Cusco",
                "horario": "Acceso libre (mejor visita al amanecer o atardecer)",
                "latitud": -13.5089,
                "longitud": -71.9756,
                "zonas": [
                    {
                        "nombre": "Estatua del Cristo Blanco",
                        "descripcion": (
                            "Estatua de 8 metros donada por la comunidad "
                            "arabe-palestina, simbolo de sincretismo religioso."
                        ),
                        "audioguia": (
                            "Tienes frente a ti la estatua principal del Cristo "
                            "Blanco, de 8 metros de altura, con los brazos extendidos "
                            "en senal de proteccion y paz. Esta elaborada con granito "
                            "revestido en marmol y yeso blanco que brilla intensamente "
                            "contra el cielo andino. Fue donada en 1945 por la "
                            "comunidad arabe-palestina residente en Cusco, como "
                            "muestra de gratitud por la acogida que recibieron en la "
                            "ciudad, y fue elaborada por el artesano cusqueno Ernesto "
                            "Olazo Olivera. Curiosamente, este monumento guarda cierto "
                            "paralelismo con el Cristo Redentor de Rio de Janeiro, "
                            "aunque a menor escala."
                        ),
                    },
                    {
                        "nombre": "Mirador Principal",
                        "descripcion": (
                            "Punto panoramico con una de las mejores vistas de toda la "
                            "ciudad de Cusco."
                        ),
                        "audioguia": (
                            "Desde este mirador, justo a los pies del Cristo Blanco, "
                            "se obtiene una de las vistas panoramicas mas "
                            "espectaculares de toda la ciudad de Cusco. Observa con "
                            "calma: puedes apreciar la totalidad del centro historico, "
                            "la Plaza de Armas, los caracteristicos tejados coloniales "
                            "de terracota, el extenso Valle del Cusco y la cordillera "
                            "de montanas que rodea la ciudad. Muchos guias locales "
                            "recomiendan llegar unos 30 minutos antes de la puesta de "
                            "sol, ya que el cambio de luz sobre el valle ocurre de "
                            "forma progresiva y suele considerarse la mejor ventana de "
                            "tiempo para fotografias desde este mirador."
                        ),
                    },
                    {
                        "nombre": "Cerro Pukamoqo (Area Inca)",
                        "descripcion": (
                            "Cerro sagrado vinculado a la Pachamama, con caminos "
                            "ancestrales hacia Sacsayhuaman."
                        ),
                        "audioguia": (
                            "Estas en el cerro Pukamoqo, cuyo nombre significa \"Cerro "
                            "Rojo\" en quechua. Mucho antes de que existiera el "
                            "monumento al Cristo Blanco, este fue un lugar sagrado "
                            "para los incas, estrechamente vinculado al culto de la "
                            "Pachamama, la Madre Tierra. Este sector conecta "
                            "directamente con el Centro Arqueologico de Sacsayhuaman y "
                            "todavia conserva tramos de caminos peatonales de origen "
                            "ancestral. El nombre \"Cerro Rojo\" hace referencia al "
                            "color que adquiere la tierra de este sector durante el "
                            "atardecer."
                        ),
                    },
                    {
                        "nombre": "Mirador de Sacsayhuaman (Conexion)",
                        "descripcion": (
                            "Mirador cercano al Cristo Blanco con vista directa a la "
                            "fortaleza inca de Sacsayhuaman."
                        ),
                        "audioguia": (
                            "A poca distancia caminando desde el Cristo Blanco "
                            "encontraras el mirador de Sacsayhuaman, que ofrece una "
                            "perspectiva todavia mas amplia y elevada del valle "
                            "cusqueno. Muchos visitantes aprovechan la cercania entre "
                            "ambos puntos para combinar las dos visitas en una sola "
                            "jornada de recorrido a pie. Desde aqui podras apreciar "
                            "con gran claridad la imponente fortaleza inca de "
                            "Sacsayhuaman, reconocida mundialmente por sus enormes "
                            "bloques de piedra ensamblados con precision milimetrica."
                        ),
                    },
                ],
            },
        ]

        # ============================================================
        # INSERCION EN BASE DE DATOS
        # ============================================================
        for sitio_info in sitios_data:
            sitio = SitioArqueologico(
                nombre=sitio_info["nombre"],
                descripcion=sitio_info["descripcion"],
                ubicacion=sitio_info["ubicacion"],
                horario=sitio_info["horario"],
                activo=True
            )
            db.add(sitio)
            db.commit()

            for orden, zona_info in enumerate(sitio_info["zonas"], start=1):
                zona = Zona(
                    sitio_id=sitio.id,
                    nombre=zona_info["nombre"],
                    descripcion=zona_info["descripcion"],
                    orden=orden,
                    latitud=sitio_info["latitud"],
                    longitud=sitio_info["longitud"],
                    activa=True
                )
                db.add(zona)
                db.commit()

                # Contenido: guion de audioguia (tipo texto, se usara como base
                # para grabar o generar el audio en espanol)
                contenido_audioguia = Contenido(
                    zona_id=zona.id,
                    tipo="texto",
                    idioma="es",
                    titulo=f"Audioguia: {zona_info['nombre']}",
                    texto=zona_info["audioguia"],
                )
                db.add(contenido_audioguia)

                # Codigo QR de la zona
                qr = CodigoQR(
                    zona_id=zona.id,
                    codigo=str(uuid.uuid4()),
                    url_destino=f"https://quriy.onrender.com/zonas/{zona.id}",
                    activo=True
                )
                db.add(qr)

            db.commit()

        print("Base de datos poblada exitosamente!")
        print(f"   - Admin: admin@quriy.com / admin123")
        print(f"   - Turista ES: turista@quriy.com / turista123")
        print(f"   - Turista EN: tourist@quriy.com / tourist123")
        print(f"   - Sitios: {db.query(SitioArqueologico).count()}")
        print(f"   - Zonas: {db.query(Zona).count()}")
        print(f"   - Contenidos: {db.query(Contenido).count()}")
        print(f"   - QRs: {db.query(CodigoQR).count()}")

    finally:
        db.close()


if __name__ == "__main__":
    poblar_base_de_datos()