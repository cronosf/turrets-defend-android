enum AppLanguage { es, en }

/// Lightweight hand-rolled localization: the string set is small enough that
/// full intl/ARB tooling would be overkill, so this keeps every user-facing
/// string in one typed place instead.
class Strings {
  const Strings(this.lang);

  final AppLanguage lang;
  bool get _es => lang == AppLanguage.es;

  String get tapToPlay => _es ? 'TOCA PARA JUGAR' : 'TAP TO PLAY';
  String bestWave(int n) => _es ? 'Mejor oleada: $n' : 'Best wave: $n';
  String get howToPlay => _es ? '¿Cómo Jugar?' : 'How to play?';

  String level(int n) => _es ? 'NIVEL $n' : 'LEVEL $n';
  String turretLevel(int n) => _es ? 'Nvl $n' : 'Lvl $n';
  String baseLabel(int hp, int max) => 'BASE $hp/$max';
  String enemiesLabel(int resolved, int total) =>
      _es ? 'ENEMIGOS $resolved/$total' : 'ENEMIES $resolved/$total';

  String get free => _es ? 'GRATIS' : 'FREE';
  String buy(int cost) => _es ? 'COMPRAR  \$$cost' : 'BUY  \$$cost';
  String get buyMenu => _es ? 'COMPRAR' : 'BUY';
  String get sell => _es ? 'VENDER' : 'SELL';
  String get buyLevelDialogTitle =>
      _es ? 'Elige una torreta' : 'Choose a turret';
  String buyLevelOption(int level, int cost) =>
      _es ? 'Nivel $level  —  \$$cost' : 'Level $level  —  \$$cost';
  String get gridFullMessage => _es
      ? 'No hay espacio libre en el tablero.'
      : 'No empty space on the board.';
  String get notEnoughMoneyMessage =>
      _es ? 'No tienes suficiente dinero.' : "You don't have enough money.";
  String get sellModeHint => _es
      ? 'Modo vender activo: toca una torreta para venderla'
      : 'Sell mode active: tap a turret to sell it';

  String get settingsTitle => _es ? 'AJUSTES' : 'SETTINGS';
  String get music => _es ? 'Música' : 'Music';
  String get sound => _es ? 'Sonido' : 'Sound';
  String get vibration => _es ? 'Vibración' : 'Vibration';
  String get tips => _es ? 'Consejos' : 'Tips';
  String get language => _es ? 'Idioma' : 'Language';
  String get guide => _es ? 'Guía' : 'Guide';
  String get help => _es ? 'Ayuda' : 'Help';
  String get close => _es ? 'CERRAR' : 'CLOSE';

  String get baseDestroyed => _es ? 'BASE DESTRUIDA' : 'BASE DESTROYED';
  String get bossFightTitle => _es ? 'COMBATE CON JEFE' : 'BOSS FIGHT';
  String get bossLevelLabel => _es ? 'NIVEL DE BOSS' : 'BOSS LEVEL';
  String get bossDefeatedTitle => _es ? 'BOSS ELIMINADO' : 'BOSS DEFEATED';
  String get achievementUnlockedLabel =>
      _es ? 'Logro conseguido' : 'Achievement unlocked';
  String get achievementRepeatLabel =>
      _es ? 'Ya tienes este logro' : 'You already have this figure';
  String achievementName(int id) => _es ? 'Logro #$id' : 'Achievement #$id';
  String get bossContinueLabel => _es ? 'CONTINUAR' : 'CONTINUE';
  String waveReached(int n) =>
      _es ? 'Oleada alcanzada: $n' : 'Wave reached: $n';
  String get playAgain => _es ? 'JUGAR DE NUEVO' : 'PLAY AGAIN';
  String get backToHome => _es ? 'VOLVER' : 'BACK';

  String get developedBy => _es ? 'Desarrollado por' : 'Developed by';
  String get allRightsReserved =>
      _es ? 'Todos los derechos reservados.' : 'All rights reserved.';

  String get navProfile => _es ? 'Mi perfil' : 'My profile';
  String get navRanking => _es ? 'Ranking' : 'Ranking';
  String get navShop => _es ? 'Tienda' : 'Shop';
  String get navSettings => _es ? 'Ajustes' : 'Settings';
  String get comingSoon => _es ? 'Próximamente' : 'Coming soon';

  String get scoreLabel => _es ? 'PUNTOS' : 'SCORE';
  String get rankingTitle => _es ? 'Ranking' : 'Ranking';
  String get bestScoreLabel => _es ? 'Mejor puntuación' : 'Best score';
  String get bestWaveLabel => _es ? 'Mejor oleada' : 'Best wave';
  String get lastRunLabel => _es ? 'Última partida' : 'Last run';
  String lastRunSummary(int wave, int points) =>
      _es ? 'Oleada $wave · $points pts' : 'Wave $wave · $points pts';
  String get noRunsYet => _es
      ? 'Todavía no jugaste ninguna partida.'
      : "You haven't played a run yet.";
  String get rankingServerNote => _es
      ? 'Por ahora estas son tus estadísticas locales. El ranking global entre jugadores llega cuando se conecte el servidor.'
      : "These are your local stats for now. A global ranking between players is coming once the server is connected.";

  // --- Login / Registro ------------------------------------------------
  String get loginTitle => _es ? 'Iniciar sesión' : 'Log in';
  String get registerTitle => _es ? 'Crear cuenta' : 'Create account';
  String get usernameOrEmail => _es ? 'Usuario o correo' : 'Username or email';
  String get username => _es ? 'Nombre de usuario' : 'Username';
  String get email => _es ? 'Correo electrónico' : 'Email';
  String get country => _es ? 'País' : 'Country';
  String get selectCountry =>
      _es ? 'Selecciona tu país' : 'Select your country';
  String get password => _es ? 'Contraseña' : 'Password';
  String get confirmPassword =>
      _es ? 'Confirmar contraseña' : 'Confirm password';
  String get rememberMe => _es ? 'Recordar mi sesión' : 'Remember me';
  String get logIn => _es ? 'INICIAR SESIÓN' : 'LOG IN';
  String get createAccount => _es ? 'CREAR CUENTA' : 'CREATE ACCOUNT';
  String get orContinueWith => _es ? 'o continúa con' : 'or continue with';
  String get continueWithGoogle =>
      _es ? 'Continuar con Google' : 'Continue with Google';
  String get noAccountYet =>
      _es ? '¿No tienes cuenta? ' : "Don't have an account? ";
  String get registerLink => _es ? 'Regístrate' : 'Sign up';
  String get haveAccountAlready =>
      _es ? '¿Ya tienes cuenta? ' : 'Already have an account? ';
  String get loginLink => _es ? 'Inicia sesión' : 'Log in';

  String get acceptTermsPrefix => _es ? 'Acepto los ' : 'I accept the ';
  String get termsLinkLabel =>
      _es ? 'Términos y Condiciones' : 'Terms and Conditions';
  String get termsTitle =>
      _es ? 'Términos y Condiciones de uso' : 'Terms and Conditions of use';
  String get termsBody => _es
      ? 'TurretCron es una aplicación desarrollada y de propiedad exclusiva de '
            'CRONOSF DEV.\n\n'
            '1. Propiedad intelectual: todo el contenido de la aplicación '
            '(código, diseño, marcas, arte y sonido) es propiedad de CRONOSF DEV '
            'o de sus licenciantes. Queda prohibida la reproducción, '
            'distribución, modificación o explotación total o parcial de la '
            'aplicación sin autorización previa y por escrito de CRONOSF DEV.\n\n'
            '2. Cuenta de usuario: eres responsable de mantener la '
            'confidencialidad de tus credenciales de acceso y de toda '
            'actividad realizada desde tu cuenta.\n\n'
            '3. Uso de datos: recopilamos los datos necesarios para el '
            'funcionamiento de la cuenta (correo, nombre de usuario, progreso '
            'de juego y compras) y no los compartimos con terceros salvo que '
            'la ley lo exija o sea necesario para procesar pagos.\n\n'
            '4. Compras: las compras dentro de la aplicación son gestionadas '
            'por el proveedor de pago correspondiente y están sujetas a sus '
            'propios términos.\n\n'
            'Al crear una cuenta, confirmas que aceptas estos términos.'
      : 'TurretCron is an application developed and exclusively owned by '
            'CRONOSF DEV.\n\n'
            '1. Intellectual property: all content in the application (code, '
            'design, trademarks, art and sound) is owned by CRONOSF DEV or its '
            'licensors. Reproduction, distribution, modification or '
            'exploitation of the application, in whole or in part, without '
            "CRONOSF DEV's prior written authorization is prohibited.\n\n"
            '2. User account: you are responsible for keeping your login '
            'credentials confidential and for all activity carried out from '
            'your account.\n\n'
            '3. Data use: we collect the data needed to run the account '
            '(email, username, game progress and purchases) and do not share '
            'it with third parties unless required by law or needed to '
            'process payments.\n\n'
            '4. Purchases: in-app purchases are handled by the relevant '
            'payment provider and are subject to its own terms.\n\n'
            'By creating an account, you confirm that you accept these terms.';
  String get mustAcceptTerms => _es
      ? 'Debes aceptar los Términos y Condiciones para continuar'
      : 'You must accept the Terms and Conditions to continue';
  String get backendNotConnectedYet => _es
      ? 'Vista previa: todavía falta conectar esto con el servidor.'
      : "Preview only: this isn't connected to the server yet.";
  String get googleSignInNotConfigured => _es
      ? 'El inicio de sesión con Google todavía no está configurado.'
      : "Google Sign-In isn't configured yet.";
  String get passwordsDontMatch =>
      _es ? 'Las contraseñas no coinciden' : "Passwords don't match";
  String get fieldRequired =>
      _es ? 'Este campo es obligatorio' : 'This field is required';
  String get retry => _es ? 'Reintentar' : 'Retry';
  String get loadingLabel => _es ? 'Cargando…' : 'Loading…';

  // --- Ranking global (servidor) ----------------------------------------
  String get globalRankingTitle => _es ? 'Ranking global' : 'Global ranking';
  String get globalRankingLoadError => _es
      ? 'No se pudo cargar el ranking global.'
      : "Couldn't load the global ranking.";
  String get notLoggedInHint => _es
      ? 'Inicia sesión para guardar tu progreso en el ranking global.'
      : 'Log in to save your progress to the global ranking.';
  String rankPositionLabel(int n) => '#$n';
  // "SCORE" reads the same in Spanish, so it's never translated — only the
  // wave column label switches (OLA/WAVE).
  String get rankingScoreColumnLabel => 'SCORE';
  String get rankingWaveColumnLabel => _es ? 'OLA' : 'WAVE';
  String get rankingCountryColumnLabel => _es ? 'País' : 'Ctry';

  // --- Tienda (servidor + PayPal) ----------------------------------------
  String get shopTitle => navShop;
  String get shopEmpty => _es
      ? 'No hay artículos disponibles por ahora.'
      : 'No items available right now.';
  String get shopLoadError =>
      _es ? 'No se pudo cargar la tienda.' : "Couldn't load the shop.";
  String buyItem(String price, String currency) =>
      _es ? 'COMPRAR $currency $price' : 'BUY $currency $price';
  String get alreadyOwned => _es ? 'Ya lo tienes' : 'Already owned';
  String get purchaseApproving =>
      _es ? 'Verificando el pago…' : 'Verifying payment…';
  String get purchaseSuccess =>
      _es ? '¡Compra realizada!' : 'Purchase complete!';
  String get purchaseCancelled =>
      _es ? 'Compra cancelada.' : 'Purchase cancelled.';
  String get purchaseError => _es
      ? 'No se pudo completar la compra.'
      : "Couldn't complete the purchase.";
  String get shopLoginRequired => _es
      ? 'Inicia sesión para comprar en la tienda.'
      : 'Log in to buy from the shop.';

  // --- Actualizaciones -----------------------------------------------------
  String get updateAvailableTitle =>
      _es ? 'Nueva versión disponible' : 'New version available';
  String updateAvailableBody(String version) => _es
      ? 'Hay una nueva versión ($version) de TurretCron lista para descargar.'
      : 'A new version ($version) of TurretCron is ready to download.';
  String get updateDownload => _es ? 'DESCARGAR' : 'DOWNLOAD';
  String get updateLater => _es ? 'Más tarde' : 'Later';

  // --- Mi Perfil -----------------------------------------------------------
  String get profileTitle => _es ? 'Mi Perfil' : 'My Profile';
  String get greetingHello => _es ? 'Hola' : 'Hello';
  String get editProfile => _es ? 'Editar perfil' : 'Edit profile';
  String get menuMyPurchases => _es ? 'Mis compras' : 'My purchases';
  String get menuCustomize => _es ? 'Mi personalización' : 'My customization';
  String get menuAchievements => _es ? 'Logros' : 'Achievements';
  String get menuNationalRanking =>
      _es ? 'Ranking nacional' : 'National ranking';
  String get menuNotifications => _es ? 'Notificaciones' : 'Notifications';
  String get notificationsHint => _es
      ? 'Aún no enviamos notificaciones, pero ya puedes dejarlas activadas.'
      : "We don't send notifications yet, but you can leave these on.";
  String get logOut => _es ? 'Cerrar sesión' : 'Log out';
  String get profileLoadError =>
      _es ? 'No se pudo cargar tu perfil.' : "Couldn't load your profile.";

  // --- Editar perfil ---------------------------------------------------------
  String get editProfileTitle => _es ? 'Editar perfil' : 'Edit profile';
  String get fullNameLabel => _es ? 'Nombre completo' : 'Full name';
  String get newPasswordLabel =>
      _es ? 'Nueva contraseña (opcional)' : 'New password (optional)';
  String get confirmNewPasswordLabel =>
      _es ? 'Confirmar nueva contraseña' : 'Confirm new password';
  String get saveChanges => _es ? 'GUARDAR CAMBIOS' : 'SAVE CHANGES';
  String get profileUpdated => _es ? 'Perfil actualizado.' : 'Profile updated.';
  String get usernameEmailNotEditable => _es
      ? 'El usuario y el correo no se pueden cambiar.'
      : "Username and email can't be changed.";

  // --- Mis compras -------------------------------------------------------
  String get myPurchasesTitle => menuMyPurchases;
  String get noPurchasesYet => _es
      ? 'Todavía no hiciste ninguna compra.'
      : "You haven't made any purchases yet.";
  String get purchasesLoadError => _es
      ? 'No se pudieron cargar tus compras.'
      : "Couldn't load your purchases.";
  String purchaseStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return _es ? 'Pagado' : 'Paid';
      case 'pending':
        return _es ? 'Pendiente' : 'Pending';
      case 'failed':
        return _es ? 'Fallido' : 'Failed';
      case 'cancelled':
        return _es ? 'Cancelado' : 'Cancelled';
      case 'refunded':
        return _es ? 'Reembolsado' : 'Refunded';
      default:
        return status;
    }
  }

  // --- Logros --------------------------------------------------------------
  String get achievementsTitle => menuAchievements;
  String get achievementsHint => _es
      ? 'Derrota bosses para conseguir figuras de colección.\nLas últimas son las más difíciles.'
      : 'Defeat bosses to earn collectible figures.\nThe last ones are the hardest to get.';
  String achievementsPageLabel(int page, int totalPages) =>
      _es ? 'Página $page de $totalPages' : 'Page $page of $totalPages';

  // --- Mi personalización --------------------------------------------------
  String get customizeTitle => menuCustomize;
  String get noItemsOwnedYet => _es
      ? 'Todavía no tienes items comprados.'
      : "You don't own any items yet.";
  String get equippedLabel => _es ? 'Equipado' : 'Equipped';
  String get equipAction => _es ? 'Equipar' : 'Equip';
  String get goToShop => _es ? 'Ir a la tienda' : 'Go to shop';
  String get basicItemName => _es ? 'Básico' : 'Basic';
  String get basicItemDescription => _es
      ? 'El aspecto original del juego, sin ningún skin aplicado.'
      : "The game's original look, with no skin applied.";
  String categoryLabel(String category) {
    switch (category) {
      case 'turret_skin':
        return _es ? 'Skins de torreta' : 'Turret skins';
      case 'bullet_effect':
        return _es ? 'Efectos de bala' : 'Bullet effects';
      case 'mob_skin':
        return _es ? 'Skins de enemigos' : 'Enemy skins';
      case 'boss_skin':
        return _es ? 'Skins de jefes' : 'Boss skins';
      case 'bundle':
        return _es ? 'Paquetes' : 'Bundles';
      default:
        return category;
    }
  }

  // --- Categorías de la tienda (menú lateral) ---------------------------
  String shopCategoryShortLabel(String category) {
    switch (category) {
      case 'turret_skin':
        return 'Turrets';
      case 'bullet_effect':
        return 'Bullets';
      case 'mob_skin':
        return 'Mobs';
      case 'boss_skin':
        return 'Bosses';
      case 'bundle':
        return 'Bundle';
      default:
        return category;
    }
  }

  // --- Sub-slots dentro de mob_skin/boss_skin (ver shopSubSlotsFor) -----
  String shopSubSlotLabel(String category, String subSlot) {
    if (category == 'mob_skin') {
      switch (subSlot) {
        case 'ground':
          return _es ? 'Terrestres' : 'Ground';
        case 'fly':
          return _es ? 'Voladores' : 'Flying';
        case 'hybrid':
          return _es ? 'Híbridos' : 'Hybrid';
      }
    }
    // Boss slot ids are proper nouns — same spelling in both languages.
    return subSlot[0].toUpperCase() + subSlot.substring(1);
  }

  // --- Nombres/descripciones de items de la tienda ---------------------
  // shop_items.name/description viven en español en la base de datos (ver
  // server/database/seed.sql) — se traducen aquí por SKU en vez de
  // depender de que el servidor devuelva el idioma correcto, ya que la
  // tabla no tiene columnas por idioma. Un SKU sin entrada cae al texto
  // que mandó el servidor tal cual.
  String shopItemName(String sku, String fallback) {
    // Bullet effect names drop the generic "Disparo"/"Shot" prefix in
    // both languages — the category header ("Bullets"/"Efectos de bala")
    // already says what kind of item this is, repeating it in every
    // single name was just noise.
    switch (sku) {
      case 'bullet_fx_laser_red':
        return _es ? 'Láser Rojo' : 'Red Laser';
      case 'bullet_fx_plasma_purple':
        return _es ? 'Plasma Púrpura' : 'Purple Plasma';
      case 'bullet_fx_neon_green':
        return _es ? 'Verde Neón' : 'Neon Green';
    }
    if (!_es) {
      switch (sku) {
        case 'turret_skin_blue':
          return 'Futuristic Blue Turret';
        case 'turret_skin_green':
          return 'Neon Green Turret';
        case 'turret_skin_crimson':
          return 'Crimson Turret';
        case 'bundle_blue_pack':
          return 'Full Blue Pack';
        case 'mob_skin_plant1':
          return 'Crimson Plant';
        case 'mob_skin_plant2':
          return 'Azure Plant';
        case 'mob_skin_plant3':
          return 'Star Plant';
        case 'mob_skin_slime1':
          return 'Emerald Slime';
        case 'mob_skin_slime2':
          return 'Sapphire Slime';
        case 'mob_skin_slime3':
          return 'Amber Slime';
        case 'boss_skin_golem1':
          return 'Crystal Golem';
        case 'boss_skin_golem3':
          return 'Lava Golem';
      }
    }
    return fallback;
  }

  String shopItemDescription(String sku, String fallback) {
    if (!_es) {
      switch (sku) {
        case 'turret_skin_blue':
          return 'Gives all your turrets a high-tech cyan-blue finish.';
        case 'turret_skin_green':
          return 'A neon green tint for all your turrets.';
        case 'turret_skin_crimson':
          return 'A bold red finish for your turrets.';
        case 'bullet_fx_laser_red':
          return 'Changes your shots into a red laser with a trail.';
        case 'bullet_fx_plasma_purple':
          return 'Shots with a bright purple plasma effect.';
        case 'bullet_fx_neon_green':
          return 'Shots with a glowing neon green effect.';
        case 'bundle_blue_pack':
          return 'Futuristic Blue Turret + Red Laser, bundled at a discount.';
        case 'mob_skin_plant1':
        case 'mob_skin_plant2':
        case 'mob_skin_plant3':
          return 'Replaces the classic ground mobs with this plant variant.';
        case 'mob_skin_slime1':
        case 'mob_skin_slime2':
        case 'mob_skin_slime3':
          return 'Replaces the classic hybrid mobs with this slime variant.';
        case 'boss_skin_golem1':
        case 'boss_skin_golem3':
          return "Changes the Golem boss's look to this variant.";
      }
    }
    return fallback;
  }

  // --- Ranking nacional --------------------------------------------------
  String get nationalRankingTitle => menuNationalRanking;
  String get nationalRankingNoCountry => _es
      ? 'Primero selecciona tu país en tu perfil, en "Editar perfil".'
      : 'First select your country in your profile, under "Edit profile".';

  // --- Modal de usuario para nuevas cuentas de Google -----------------------
  String get googleSetupTitle =>
      _es ? 'Elige tu nombre de usuario' : 'Choose your username';
  String get googleSetupSubtitle => _es
      ? 'Es la primera vez que entras con esta cuenta de Google. Elige un nombre de usuario para tu perfil.'
      : "It's the first time you're signing in with this Google account. Choose a username for your profile.";
  String get usernameLengthHint =>
      _es ? 'Entre 4 y 12 caracteres' : 'Between 4 and 12 characters';
  String get googleSetupSubmit => _es ? 'CONTINUAR' : 'CONTINUE';
  String get cancelAndLogOut =>
      _es ? 'Cancelar y cerrar sesión' : 'Cancel and log out';
  String get usernameLengthError => _es
      ? 'Debe tener entre 4 y 12 caracteres'
      : 'Must be between 4 and 12 characters';

  // --- Disponibilidad en tiempo real (registro / setup de Google) -----------
  String get checkingAvailability => _es ? 'Verificando…' : 'Checking…';
  String get usernameAvailable => _es ? 'Disponible' : 'Available';
  String get usernameTaken => _es ? 'Ya está en uso' : 'Already taken';
  String get emailAvailable => _es ? 'Disponible' : 'Available';
  String get emailTaken => _es ? 'Ya está en uso' : 'Already in use';

  String get guideTitle => _es ? 'Guía' : 'Guide';
  List<(String, String)> get guideSections => _es
      ? const [
          (
            'Objetivo',
            'Sobrevive la mayor cantidad de oleadas posible. El modo es '
                'infinito: los enemigos nunca dejan de venir y se vuelven más '
                'fuertes con cada oleada.',
          ),
          (
            'El tablero',
            'La cuadrícula de la parte inferior cumple dos funciones a la '
                'vez: ahí colocas tus torretas y desde ahí disparan a los '
                'enemigos que bajan por el campo de batalla.',
          ),
          (
            'Fusionar torretas',
            'Arrastra una torreta sobre otra del mismo nivel para '
                'fusionarlas en una torreta de nivel superior, más fuerte, '
                'con más daño y más alcance.',
          ),
          (
            'Conseguir torretas',
            'Usa el botón COMPRAR para elegir y pagar el nivel de torreta '
                'que quieras (del 1 al 10, cada uno con su propio precio '
                'fijo), o el botón GRATIS para obtener una torreta de nivel '
                '1 sin costo cada cierto tiempo de espera.',
          ),
          (
            'Vender torretas',
            'Activa el botón VENDER y luego toca cualquier torreta del '
                'tablero para venderla a cambio de monedas.',
          ),
          (
            'Oleadas infinitas',
            'Cada oleada trae más enemigos, más resistentes y más rápidos. '
                'Con el paso de las oleadas se desbloquean nuevos tipos de '
                'enemigos: terrestres, voladores e híbridos.',
          ),
          (
            'Combates contra bosses',
            'Cada 5 oleadas aparece un boss: un enemigo único, enorme y muy '
                'resistente, en vez de la oleada normal. Al derrotarlo '
                'consigues una figura de colección para tu álbum de logros. '
                'Como el modo es infinito, los bosses se repiten y son cada '
                'vez más fuertes.',
          ),
          (
            'La base',
            'Si un enemigo llega hasta el final del campo, le quita vida a '
                'tu base. Si la vida de la base llega a 0, la partida '
                'termina y se guarda la oleada más alta alcanzada.',
          ),
        ]
      : const [
          (
            'Objective',
            'Survive as many waves as you can. The mode is endless: '
                'enemies never stop coming and get stronger with every '
                'wave.',
          ),
          (
            'The board',
            'The grid at the bottom does two jobs at once: it is where you '
                'place your turrets, and it is also the firing line they '
                'shoot from at the enemies coming down the battlefield.',
          ),
          (
            'Merging turrets',
            'Drag a turret onto another of the same level to merge them '
                'into a stronger, higher-level turret with more damage and '
                'range.',
          ),
          (
            'Getting turrets',
            'Use the BUY button to pick and pay for the turret level you '
                'want (1 through 10, each with its own fixed price), or the '
                'FREE button to get a level-1 turret at no cost after a '
                'short wait.',
          ),
          (
            'Selling turrets',
            'Turn on the SELL button, then tap any turret on the board to '
                'sell it for coins.',
          ),
          (
            'Endless waves',
            'Every wave brings more enemies, tougher and faster. As waves '
                'go on, new enemy types unlock: ground, flying, and hybrid.',
          ),
          (
            'Boss fights',
            'A boss appears every 5 waves instead of the usual swarm: a '
                'single huge, very tough enemy. Defeating it earns a '
                'collectible figure for your achievements album. Since the '
                'mode is endless, bosses keep coming back and get stronger '
                'each time.',
          ),
          (
            'The base',
            "If an enemy reaches the end of the field, it damages your "
                "base. If the base's health hits 0, the run ends and your "
                'highest wave is saved.',
          ),
        ];
}
