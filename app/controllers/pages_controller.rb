class PagesController < ApplicationController
  def home
  end

  def about
    @team_members = [
      {
        name: "Team Member One",
        role: "Front-End Developer",
        bio: "Focused on building polished, accessible UI in Rails using ERB views and Tailwind CSS. Loves clean layouts and meaningful animations.",
        image: "team_member_1.svg"
      },
      {
        name: "Team Member Two",
        role: "Back-End Developer",
        bio: "Comfortable in Ruby and SQL. Drives the controller, model, and database layers and keeps our routes tidy.",
        image: "team_member_2.svg"
      },
      {
        name: "Team Member Three",
        role: "Full-Stack / Project Lead",
        bio: "Coordinates milestones, handles deployments, and bridges the gap between front-end and back-end work for the team.",
        image: "team_member_3.svg"
      }
    ]
  end

  def contact
  end

  def submit_contact
    redirect_to contact_path, notice: "Thanks! This is a non-functional demo form, so nothing was actually sent."
  end
end
