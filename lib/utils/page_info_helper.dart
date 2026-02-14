import 'package:flutter/material.dart';
import 'package:breedly/utils/constants.dart';

/// Hjelpeklasse for å vise side-info i appen
/// Gir brukeren en enkel forklaring av hva siden gjør og hvordan den brukes
class PageInfoHelper {
  /// Viser en bottom sheet med informasjon om siden
  static void showPageInfo(
    BuildContext context, {
    required String title,
    required String description,
    required List<PageInfoItem> features,
    String? tip,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Håndtak
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: ThemeOpacity.low(context)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Slik bruker du denne siden',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Beskrivelse
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Funksjoner
                    const Text(
                      'Funksjoner',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: ThemeOpacity.low(context)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              feature.icon,
                              color: feature.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  feature.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    // Tips
                    if (tip != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: ThemeOpacity.low(context)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: ThemeOpacity.high(context)),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tips',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tip,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bygger en info-knapp for app bar
  static Widget buildInfoButton(
    BuildContext context, {
    required String title,
    required String description,
    required List<PageInfoItem> features,
    String? tip,
  }) {
    return IconButton(
      onPressed: () => showPageInfo(
        context,
        title: title,
        description: description,
        features: features,
        tip: tip,
      ),
      icon: const Icon(Icons.help_outline_rounded),
      tooltip: 'Hjelp',
    );
  }
}

/// Representerer en funksjon/feature på en side
class PageInfoItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const PageInfoItem({
    required this.icon,
    required this.title,
    required this.description,
    this.color = Colors.blue,
  });
}

// =============================================================================
// PREDEFINERTE SIDE-INFO
// =============================================================================

/// Predefinert info for ulike sider i appen
class PageInfoContent {
  // Hunder-siden
  static const dogsScreen = (
    title: 'Mine hunder',
    description: 'Her får du oversikt over alle hundene dine. Du kan filtrere mellom alle hunder, tisper og hanner. Registrer både egne avlshunder og forfedre for stamtavler.',
    features: [
      PageInfoItem(
        icon: Icons.add_rounded,
        title: 'Legg til hund',
        description: 'Trykk på + knappen for å registrere en ny hund med navn, rase, fødselsdato og mer.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.filter_list_rounded,
        title: 'Filtrer etter kjønn',
        description: 'Bruk fanene øverst for å se alle hunder, bare tisper, eller bare hanner.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.account_tree_rounded,
        title: 'Kun stamtavle',
        description: 'Merk hunder som "kun stamtavle" for å skjule dem fra hovedlisten, men beholde dem i stamtavler.',
        color: Colors.purple,
      ),
      PageInfoItem(
        icon: Icons.event_busy_rounded,
        title: 'Dødsdato',
        description: 'Registrer dødsdato for avdøde hunder. De vises fortsatt i historikk og stamtavler.',
        color: Colors.grey,
      ),
      PageInfoItem(
        icon: Icons.touch_app_rounded,
        title: 'Se detaljer',
        description: 'Trykk på en hund for å se fullstendig profil med helse, valpinger og mer.',
        color: Colors.orange,
      ),
    ],
    tip: 'Bruk "kun stamtavle" for forfedre du ikke eier selv - da holdes hundelisten ryddig mens stamtavlene er komplette.',
  );

  // Kull-siden
  static const littersScreen = (
    title: 'Kull',
    description: 'Oversikt over alle kullene dine. Se aktive kull med valper, planlagte kull, og arkiverte kull.',
    features: [
      PageInfoItem(
        icon: Icons.add_rounded,
        title: 'Nytt kull',
        description: 'Trykk på + for å registrere et nytt kull eller planlegge et fremtidig kull.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.calculate_rounded,
        title: 'Innavlsberegning',
        description: 'Se innavlskoeffisient (COI) for kullet basert på foreldrenes stamtavle.',
        color: Colors.purple,
      ),
      PageInfoItem(
        icon: Icons.calendar_month_rounded,
        title: 'Planlagte kull',
        description: 'Kull med fødselsdato i fremtiden vises under "Planlagt" - perfekt for drektighetsoppfølging.',
        color: Colors.orange,
      ),
      PageInfoItem(
        icon: Icons.archive_rounded,
        title: 'Arkiv',
        description: 'Eldre kull (over 12 uker) flyttes automatisk til arkivet.',
        color: Colors.grey,
      ),
    ],
    tip: 'Registrer forfedre med registreringsnummer for nøyaktig COI-beregning.',
  );

  // Kulldetaljer
  static const litterDetail = (
    title: 'Kulldetaljer',
    description: 'Her administrerer du alt om kullet - fra valper og veiing til bilder og dokumenter.',
    features: [
      PageInfoItem(
        icon: Icons.info_outline_rounded,
        title: 'Info-fanen',
        description: 'Oversikt over kullet med foreldreinformasjon, alder og valpestatus.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.pets_rounded,
        title: 'Valper-fanen',
        description: 'Legg til og administrer valpene. Trykk på en valp for å redigere info.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.share_rounded,
        title: 'Del oppdatering',
        description: 'Del valpeoppdateringer med kjøpere via SMS, e-post eller andre apper.',
        color: Colors.orange,
      ),
      PageInfoItem(
        icon: Icons.medical_services_rounded,
        title: 'Helseattest',
        description: 'Generer PDF-helseattest for veterinærbesøk.',
        color: Colors.red,
      ),
      PageInfoItem(
        icon: Icons.image_rounded,
        title: 'Galleri-fanen',
        description: 'Last opp bilder av kullet og valpene.',
        color: Colors.pink,
      ),
    ],
    tip: 'Bruk "Del"-knappen på hver valp for å sende oppdateringer til kjøperen.',
  );

  // Kjøpere-siden
  static const buyersScreen = (
    title: 'Kjøpere',
    description: 'Hold oversikt over alle valpekjøpere og interessenter. Her kan du lagre kontaktinfo og notater.',
    features: [
      PageInfoItem(
        icon: Icons.person_add_rounded,
        title: 'Ny kjøper',
        description: 'Legg til nye interessenter med navn, kontaktinfo og preferanser.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.link_rounded,
        title: 'Koble til valp',
        description: 'Koble en kjøper til en spesifikk valp når avtale er inngått.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.notes_rounded,
        title: 'Notater',
        description: 'Lagre viktig informasjon som ønsket kjønn, farge eller leveringsdato.',
        color: Colors.orange,
      ),
    ],
    tip: 'Du kan også legge til kjøperinfo direkte fra en valps profil.',
  );

  // Økonomi-siden
  static const financeScreen = (
    title: 'Økonomi',
    description: 'Spor inntekter og utgifter for oppdrettet ditt. Få oversikt over lønnsomhet per kull.',
    features: [
      PageInfoItem(
        icon: Icons.trending_up_rounded,
        title: 'Inntekter',
        description: 'Registrer salg av valper og andre inntekter.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.trending_down_rounded,
        title: 'Utgifter',
        description: 'Før opp veterinærkostnader, fôr, utstyr og andre utgifter.',
        color: Colors.red,
      ),
      PageInfoItem(
        icon: Icons.analytics_rounded,
        title: 'Statistikk',
        description: 'Se totaloversikt og lønnsomhet per kull.',
        color: Colors.blue,
      ),
    ],
    tip: 'Koble transaksjoner til spesifikke kull for å se nøyaktig lønnsomhet.',
  );

  // Kennel-siden
  static const kennelScreen = (
    title: 'Kenneladministrasjon',
    description: 'Administrer kennelinfo, medlemskap og innstillinger for oppdrettet ditt.',
    features: [
      PageInfoItem(
        icon: Icons.home_work_rounded,
        title: 'Kennelprofil',
        description: 'Oppdater kennelnavn, adresse og kontaktinformasjon.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.card_membership_rounded,
        title: 'Medlemskap',
        description: 'Se og administrer medlemskap i raseklubber og NKK.',
        color: Colors.purple,
      ),
      PageInfoItem(
        icon: Icons.description_rounded,
        title: 'Dokumenter',
        description: 'Last opp viktige dokumenter som avlsplaner og godkjenninger.',
        color: Colors.orange,
      ),
    ],
    tip: 'Komplett kennelprofil gir et profesjonelt inntrykk overfor valpekjøpere.',
  );

  // Hundehelse
  static const dogHealth = (
    title: 'Helse',
    description: 'Spor hundens helsehistorikk med vaksinasjoner, behandlinger og progesteronmålinger.',
    features: [
      PageInfoItem(
        icon: Icons.vaccines_rounded,
        title: 'Vaksinasjoner',
        description: 'Registrer og følg opp vaksinasjonsprogrammet.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.healing_rounded,
        title: 'Behandlinger',
        description: 'Loggfør avmaskinger, veterinærbesøk og andre behandlinger.',
        color: Colors.orange,
      ),
      PageInfoItem(
        icon: Icons.science_rounded,
        title: 'Progesteron',
        description: 'Registrer progesteronmålinger for optimal parringstidspunkt.',
        color: Colors.purple,
      ),
    ],
    tip: 'For tisper: Start progesteronmålinger ca. dag 5-7 etter løpstart.',
  );

  // Temperaturregistrering
  static const temperatureTracking = (
    title: 'Temperaturregistrering',
    description: 'Følg tispas temperatur før valping. Et temperaturfall på ca. 1°C indikerer at valping nærmer seg.',
    features: [
      PageInfoItem(
        icon: Icons.add_rounded,
        title: 'Registrer temperatur',
        description: 'Legg til nye målinger med dato, tid og temperatur.',
        color: Colors.red,
      ),
      PageInfoItem(
        icon: Icons.show_chart_rounded,
        title: 'Graf',
        description: 'Se temperaturutviklingen i en oversiktlig graf.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.notification_important_rounded,
        title: 'Temperaturfall',
        description: 'Systemet varsler når temperaturen faller under normalen.',
        color: Colors.orange,
      ),
    ],
tip: 'Normal temperatur er 38-39°C. Mål minst 2-3 ganger daglig de siste dagene før estimert fødsel.',
  );

  // Innstillinger
  static const settings = (
    title: 'Innstillinger',
    description: 'Tilpass appen etter dine ønsker med språk, fargetema, varsler og mer.',
    features: [
      PageInfoItem(
        icon: Icons.language_rounded,
        title: 'Språk',
        description: 'Velg mellom norsk, svensk, dansk og finsk.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.palette_rounded,
        title: 'Fargetema',
        description: 'Velg hovedfargen som passer din stil.',
        color: Colors.purple,
      ),
      PageInfoItem(
        icon: Icons.notifications_rounded,
        title: 'Varsler',
        description: 'Administrer påminnelser for behandlinger, valping og leveringer.',
        color: Colors.orange,
      ),
      PageInfoItem(
        icon: Icons.sync_rounded,
        title: 'Synkronisering',
        description: 'Data synkroniseres automatisk til skyen når du er pålogget.',
        color: Colors.green,
      ),
    ],
    tip: 'Varsler planlegges automatisk når du lagrer behandlingsplaner og leveringsdatoer.',
  );

  // Kontrakter-siden
  static const contractsScreen = (
    title: 'Kontrakter',
    description: 'Administrer alle kontrakter for oppdrettet ditt. Opprett, rediger og eksporter profesjonelle kontrakter.',
    features: [
      PageInfoItem(
        icon: Icons.add_circle_rounded,
        title: 'Nye kontrakter',
        description: 'Opprett kjøpekontrakt, reservasjonskontrakt, avlskontrakt, sameiekontrakt eller fosterkontrakt.',
        color: Colors.green,
      ),
      PageInfoItem(
        icon: Icons.edit_rounded,
        title: 'Rediger kontrakter',
        description: 'Trykk på redigeringsknappen for å oppdatere eksisterende kontrakter.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.delete_rounded,
        title: 'Slett kontrakter',
        description: 'Fjern kontrakter som ikke lenger er gyldige eller er opprettet feil.',
        color: Colors.red,
      ),
      PageInfoItem(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Eksporter PDF',
        description: 'Last ned profesjonelle PDF-kontrakter til utskrift eller digital signering.',
        color: Colors.orange,
      ),
    ],
    tip: 'Kjøpekontrakten inneholder felt for depositum, overleveringssted, stamtavle, helseattest og forsikringsoverføring.',
  );

  // Innavl/COI-beregning
  static const coiScreen = (
    title: 'Innavlsberegning',
    description: 'Beregn innavlskoeffisient (COI) for planlagte parringer. Hjelper deg å ta informerte avlsvalg.',
    features: [
      PageInfoItem(
        icon: Icons.calculate_rounded,
        title: 'COI-beregning',
        description: 'Velg mor og far for å beregne innavlsgraden for potensielle valper.',
        color: Colors.blue,
      ),
      PageInfoItem(
        icon: Icons.family_restroom_rounded,
        title: 'Felles forfedre',
        description: 'Se hvilke hunder som forekommer på begge sider av stamtavlen.',
        color: Colors.purple,
      ),
      PageInfoItem(
        icon: Icons.warning_rounded,
        title: 'Risikovurdering',
        description: 'Får fargekoding basert på COI-nivå: grønn (<6%), gul (6-12%), rød (>12%).',
        color: Colors.orange,
      ),
    ],
    tip: 'Registrer forfedre med registreringsnummer. Systemet gjenkjenner samme hund selv om den er registrert flere ganger.',
  );
}
