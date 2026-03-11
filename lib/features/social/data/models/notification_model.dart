/// Modèle de notification
class NotificationModel {
  final int idNotif;
  final int idJoueur;
  final String type; // 'message', 'challenge', 'promo', 'systeme', 'ami', 'badge'
  final String titre;
  final String contenu;
  final String canal;
  final bool estLue;
  final DateTime dateCreation;

  NotificationModel({
    required this.idNotif,
    required this.idJoueur,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.canal,
    required this.estLue,
    required this.dateCreation,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      idNotif: json['idNotif'] ?? json['id_notif'] ?? 0,
      idJoueur: json['idJoueur'] ?? json['id_joueur'] ?? 0,
      type: json['type'] ?? 'systeme',
      titre: json['titre'] ?? '',
      contenu: json['contenu'] ?? json['message'] ?? '',
      canal: json['canal'] ?? 'in-app',
      estLue: json['estLue'] == true || json['est_lue'] == true || json['lue'] == true,
      dateCreation: json['dateCreation'] != null
          ? DateTime.tryParse(json['dateCreation'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idNotif': idNotif,
      'idJoueur': idJoueur,
      'type': type,
      'titre': titre,
      'contenu': contenu,
      'canal': canal,
      'estLue': estLue,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  NotificationModel copyWith({bool? estLue}) {
    return NotificationModel(
      idNotif: idNotif,
      idJoueur: idJoueur,
      type: type,
      titre: titre,
      contenu: contenu,
      canal: canal,
      estLue: estLue ?? this.estLue,
      dateCreation: dateCreation,
    );
  }
}
