//! `SeaORM` Entity. Generated by sea-orm-codegen 0.12.15

use async_graphql::SimpleObject;
use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel, Eq, SimpleObject)]
#[sea_orm(table_name = "playlist_items")]
pub struct Model {
    #[sea_orm(primary_key)]
    pub id: i32,
    pub playlist_id: i32,
    pub file_id: i32,
    pub position: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {
    #[sea_orm(
        belongs_to = "super::media_files::Entity",
        from = "Column::FileId",
        to = "super::media_files::Column::Id",
        on_update = "Cascade",
        on_delete = "Cascade"
    )]
    MediaFiles,
    #[sea_orm(
        belongs_to = "super::playlists::Entity",
        from = "Column::PlaylistId",
        to = "super::playlists::Column::Id",
        on_update = "Cascade",
        on_delete = "Cascade"
    )]
    Playlists,
}

impl Related<super::media_files::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::MediaFiles.def()
    }
}

impl Related<super::playlists::Entity> for Entity {
    fn to() -> RelationDef {
        Relation::Playlists.def()
    }
}

impl ActiveModelBehavior for ActiveModel {}
